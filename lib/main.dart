import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// 1. ABSTRACTION & INTERFACES
// ============================================================================

/// Abstraction: Abstract base class representing any event in the fest.
abstract class FestEvent {
  final String title;
  final String venue;

  FestEvent(this.title, this.venue);

  // Abstract methods enforcing sub-class implementation
  String getEventDetails();
  IconData getIcon();

  // Concrete getter
  String get locationInfo => 'Venue: $venue';
}

/// Interface: Contracts for events that issue certificates.
abstract class Certifiable {
  void generateCertificate(String studentName);
  bool get offersCertificate;
}

// ============================================================================
// 2. MIXINS (Reusable Feature Injection)
// ============================================================================

/// Mixin adding sponsorship and budget handling to events.
mixin SponsorshipRequirement {
  double _budget = 0.0; // Encapsulated private field

  double get budget => _budget;

  void addSponsorship(double amount) {
    if (amount > 0) {
      _budget += amount;
    }
  }

  void allocateExpense(double amount) {
    if (amount <= _budget) {
      _budget -= amount;
    }
  }
}

class RegistrationData {
  final String studentName;
  final String phoneNumber;
  final String collegeName;
  final String emailAddress;
  final String eventTitle;
  final String eventVenue;
  final String eventType;
  final DateTime registeredAt;

  RegistrationData({
    required this.studentName,
    required this.phoneNumber,
    required this.collegeName,
    required this.emailAddress,
    required this.eventTitle,
    required this.eventVenue,
    required this.eventType,
    required this.registeredAt,
  });
}

// ============================================================================
// 3. ENCAPSULATION, INHERITANCE & POLYMORPHISM
// ============================================================================

/// Subclass 1: [TechnicalEvent] extends [FestEvent], uses mixin & interface
class TechnicalEvent extends FestEvent
    with SponsorshipRequirement
    implements Certifiable {
  // Encapsulation: Private members
  int _registrationsCount = 0;
  final int _maxCapacity;

  // Static Member: Tracks total fest registrations across all technical events
  static int totalFestRegistrations = 0;

  // Standard Constructor with super-initializer
  TechnicalEvent(super.title, super.venue, this._maxCapacity);

  // Named Constructor
  TechnicalEvent.codingCompetition(String title)
    : _maxCapacity = 50,
      super(title, 'Lab 302');

  // Factory Constructor: Creates specialized preset events
  factory TechnicalEvent.hackathon() {
    return TechnicalEvent('Ai and Machine Learning', 'Main Auditorium', 100);
  }

  // Getters & Setters for Encapsulated Fields
  int get registrationsCount => _registrationsCount;
  bool get hasCapacity => _registrationsCount < _maxCapacity;

  bool registerStudent() {
    if (_registrationsCount < _maxCapacity) {
      _registrationsCount++;
      totalFestRegistrations++;
      return true;
    }
    return false;
  }

  // Polymorphic Implementation of Abstract Methods
  @override
  String getEventDetails() {
    return 'Tech Event | Slots: $_registrationsCount/$_maxCapacity';
  }

  @override
  IconData getIcon() => Icons.code;

  // Interface Implementation
  @override
  bool get offersCertificate => true;

  @override
  void generateCertificate(String studentName) {
    debugPrint('Certificate generated for $studentName in $title');
  }
}

/// Subclass 2: [CulturalEvent] demonstrating different Polymorphic behavior
class CulturalEvent extends FestEvent implements Certifiable {
  final String category; // e.g., Dance, Music, Drama
  bool _isStageReady = false;

  CulturalEvent(super.title, super.venue, this.category);

  void prepareStage() {
    _isStageReady = true;
  }

  // Polymorphic Overriding
  @override
  String getEventDetails() {
    final String status = _isStageReady ? 'Stage Ready' : 'Rehearsals Ongoing';
    return 'Cultural ($category) | Status: $status';
  }

  @override
  IconData getIcon() => Icons.music_note;

  // Interface Implementation
  @override
  bool get offersCertificate => false; // Cultural events might just give trophies

  @override
  void generateCertificate(String studentName) {
    debugPrint('Participation award generated for $studentName');
  }
}

// ============================================================================
// 4. FLUTTER UI INTEGRATION
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      debugPrint('Warning: could not load .env from project root');
    }
  }

  runApp(
    const MaterialApp(
      home: CollegeFestDashboard(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class CollegeFestDashboard extends StatefulWidget {
  const CollegeFestDashboard({super.key});

  @override
  State<CollegeFestDashboard> createState() => _CollegeFestDashboardState();
}

class _CollegeFestDashboardState extends State<CollegeFestDashboard> {
  // Polymorphic List holding base type reference [FestEvent]
  late final List<FestEvent> _festEvents;
  RegistrationData? _lastRegistration;
  final List<String> _galleryImages = <String>[
    'assets/images/event_landscape_1.jpg',
    'assets/images/event_landscape_2.jpg',
    'assets/images/event_landscape_3.jpg',
  ];
  late final PageController _galleryController;
  int _galleryPageIndex = 0;
  Timer? _galleryTimer;

  static const List<String> _navItems = <String>[
    'Home',
    'Events',
    'About',
    'Gallery',
    'Contact',
  ];
  String _currentNavItem = 'Home';

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
    _startGalleryTimer();
    // Instantiating concrete subclasses via various constructors
    _festEvents = <FestEvent>[
      TechnicalEvent.hackathon(), // Factory Constructor
      TechnicalEvent.codingCompetition('Hacakathon'), // Named Constructor
      TechnicalEvent(
        'Flutter Workshop',
        'Class room 502',
        40,
      ), // Standard Constructor
      CulturalEvent(
        'Kannada Orchestor',
        'College Ground',
        'Music',
      ), // Subclass 2
    ];
  }

  @override
  void dispose() {
    _galleryTimer?.cancel();
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KLE Haveri BCA Independence Day 2026'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 58, 183, 177),
        foregroundColor: const Color.fromARGB(255, 14, 13, 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: _navItems
                  .map((String item) => _buildNavLink(item))
                  .toList(),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildFooter(),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: const Color.fromARGB(255, 44, 64, 63),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Follow Us',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildSocialIcon(
                Icons.camera_alt,
                'https://www.instagram.com/klehaveri',
              ),
              _buildSocialIcon(
                Icons.facebook,
                'https://www.facebook.com/klehaveri',
              ),
              _buildSocialIcon(
                Icons.play_circle_filled,
                'https://www.youtube.com/@klehaveri',
              ),
              _buildSocialIcon(Icons.public, 'https://klehaveri.edu.in'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String urlString) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => _openUrl(urlString),
        borderRadius: BorderRadius.circular(8),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open link: $error')));
    }
  }

  Widget _buildNavLink(String item) {
    final bool isSelected = _currentNavItem == item;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: isSelected
              ? const Color.fromARGB(255, 14, 13, 13)
              : Colors.white,
          backgroundColor: isSelected ? Colors.white : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {
          setState(() {
            _currentNavItem = item;
          });
        },
        child: Text(item),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentNavItem) {
      case 'Events':
        return _buildEventsList();
      case 'Gallery':
        return _buildGalleryView();
      case 'About':
        return _buildInfoPage(
          'About',
          'KLE Haveri BCA Independence Day 2026 is a vibrant college fest organized by the BCA '
              'department of KLE Society, Haveri. The fest brings together '
              'technical workshops, coding competitions, and cultural '
              'performances to celebrate creativity and innovation.',
        );
      case 'Contact':
        return _buildInfoPage(
          'Contact',
          'KLE Society, Haveri, Karnataka\n'
              'Phone: +91 98765 43210\n'
              'Email: fest@klehaveri.edu.in',
        );
      case 'Home':
      default:
        return _buildHomeView();
    }
  }

  Widget _buildHomeView() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double fixedAllowance = 310.0;
        final double galleryHeight = (constraints.maxHeight - fixedAllowance)
            .clamp(140.0, 600.0);
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: <Widget>[
                  _buildGallerySection(height: galleryHeight),
                  _buildEventInfoRow(),
                  _buildActionButtons(),
                  _buildSlogan(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlogan() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: <Widget>[
          Text(
            'KLE INDEPENDENCE DAY 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color.fromARGB(255, 14, 13, 13),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Develop the next generation of freedom\u2014register now to '
            'compile our rich heritage and deploy a future of endless '
            'possibilities at KLE Haveri.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 15,
              height: 1.4,
              color: Color.fromARGB(255, 14, 13, 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: _buildInfoItem(
              icon: Icons.calendar_today,
              label: 'Aug 15, 2026',
            ),
          ),
          Expanded(
            child: _buildInfoItem(
              icon: Icons.location_on,
              label: 'KLE Haveri BCA College',
              onTap: _openLocation,
            ),
          ),
          Expanded(
            child: _buildInfoItem(
              icon: Icons.people,
              label: '$_totalParticipants Participants',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final Column content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: const Color.fromARGB(255, 58, 183, 177), size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.all(4), child: content),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: <Widget>[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 58, 183, 177),
            ),
            onPressed: _goToEvents,
            icon: const Icon(Icons.calendar_view_day),
            label: const Text('View Events'),
          ),
        ],
      ),
    );
  }

  int get _totalParticipants {
    return _festEvents.fold<int>(
      0,
      (int sum, FestEvent event) =>
          sum + (event is TechnicalEvent ? event.registrationsCount : 0),
    );
  }

  void _goToEvents() {
    setState(() {
      _currentNavItem = 'Events';
    });
  }

  Future<void> _openLocation() {
    return _openUrl(
      'https://www.google.com/maps/search/?api=1&query=KLE+College+Haveri',
    );
  }

  Widget _buildGallerySection({required double height}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: height,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _galleryController,
                      onPageChanged: (int index) {
                        setState(() {
                          _galleryPageIndex = index;
                        });
                        _startGalleryTimer();
                      },
                      itemCount: _galleryImages.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Image.asset(
                          _galleryImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          cacheWidth: _imageDecodeWidth(context),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 8,
                    child: _buildGalleryArrow(
                      icon: Icons.chevron_left,
                      onPressed: _showPreviousGalleryImage,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: _buildGalleryArrow(
                      icon: Icons.chevron_right,
                      onPressed: _showNextGalleryImage,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _galleryImages.length,
              (int index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _galleryPageIndex == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _galleryPageIndex == index
                      ? const Color.fromARGB(255, 58, 183, 177)
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGalleryArrow({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black.withAlpha((0.4 * 255).round()),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  void _startGalleryTimer() {
    _galleryTimer?.cancel();
    _galleryTimer = Timer(const Duration(seconds: 3), _showNextGalleryImage);
  }

  void _showNextGalleryImage() {
    if (!mounted) return;
    if (!_galleryController.hasClients) {
      _startGalleryTimer();
      return;
    }
    _galleryController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showPreviousGalleryImage() {
    if (!mounted) return;
    if (!_galleryController.hasClients) return;
    _galleryController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildEventsList() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _festEvents.length,
          itemBuilder: (BuildContext context, int index) {
            final FestEvent event = _festEvents[index];
            return _buildEventCard(event);
          },
        ),
      ),
    );
  }

  Widget _buildGalleryView() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int crossAxisCount = (constraints.maxWidth ~/ 260).clamp(2, 4);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: _galleryImages.length,
              itemBuilder: (BuildContext context, int index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _galleryImages[index],
                    fit: BoxFit.cover,
                    cacheWidth: _imageDecodeWidth(context),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoPage(String title, String message) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }

  // Decodes images at display resolution to keep rendering fast & memory low.
  int _imageDecodeWidth(BuildContext context) {
    return (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, 1024);
  }

  // Renders UI polymorphically using base class contract [FestEvent]
  Widget _buildEventCard(FestEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: () => _openEventDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 196, 232, 233),
                  child: Icon(
                    event.getIcon(),
                    color: const Color.fromARGB(255, 58, 148, 183),
                  ), // Polymorphic Icon
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${event.locationInfo}\n${event.getEventDetails()}',
                ), // Polymorphic String
                trailing:
                    (event is Certifiable &&
                        (event as Certifiable).offersCertificate)
                    ? TextButton.icon(
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download Voucher'),
                        onPressed: () => _showVoucherEmailDialog(event),
                      )
                    : null,
              ),
              const Divider(),
              // Type-specific action triggers
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (event is TechnicalEvent) ...<Widget>[
                    Chip(
                      avatar: const Icon(Icons.people, size: 18),
                      label: Text('${event.registrationsCount} registered'),
                      visualDensity: VisualDensity.compact,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Register'),
                      onPressed: () {
                        _showRegistrationDialog(event);
                      },
                    ),
                  ],
                  if (event is CulturalEvent) ...<Widget>[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.mic, size: 16),
                      label: const Text('Lets start the program'),
                      onPressed: () {
                        setState(() {
                          event.prepareStage();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEventDetails(FestEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => EventDetailPage(
          event: event,
          onDownloadVoucher: () => _showVoucherEmailDialog(event),
        ),
      ),
    );
  }

  Future<void> _showRegistrationDialog(TechnicalEvent event) async {
    if (!event.hasCapacity) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration full for this event.')),
      );
      return;
    }

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController collegeController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setDialogState) {
            return AlertDialog(
              title: const Text('Register for Event'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Student Name',
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter student name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter phone number';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: collegeController,
                        decoration: const InputDecoration(labelText: 'College'),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter college name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter email address';
                          }
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                          });

                          final bool success = await _submitRegistration(
                            event: event,
                            studentName: nameController.text,
                            phoneNumber: phoneController.text,
                            collegeName: collegeController.text,
                            emailAddress: emailController.text,
                          );

                          if (!context.mounted) return;
                          setDialogState(() {
                            isSubmitting = false;
                          });

                          if (success) {
                            final bool registered = event.registerStudent();
                            Navigator.of(context).pop();
                            if (registered) {
                              setState(() {
                                _lastRegistration = RegistrationData(
                                  studentName: nameController.text.trim(),
                                  phoneNumber: phoneController.text.trim(),
                                  collegeName: collegeController.text.trim(),
                                  emailAddress: emailController.text.trim(),
                                  eventTitle: event.title,
                                  eventVenue: event.venue,
                                  eventType: event.runtimeType.toString(),
                                  registeredAt: DateTime.now(),
                                );
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Registration successful. Voucher ready in the event card.',
                                    ),
                                  ),
                                );
                              }
                            } else if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Registration limit reached.'),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to submit registration.'),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _submitRegistration({
    required TechnicalEvent event,
    required String studentName,
    required String phoneNumber,
    required String collegeName,
    required String emailAddress,
  }) async {
    final String supabaseUrl = Env.supabaseUrl;
    final String supabaseKey = Env.supabaseKey;

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase credentials are not configured.'),
        ),
      );
      return false;
    }

    final Uri uri = Uri.parse('$supabaseUrl/rest/v1/registrations');
    final http.Response response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Prefer': 'return=representation',
      },
      body: jsonEncode(<String, String>{
        'student_name': studentName.trim(),
        'phone_number': phoneNumber.trim(),
        'college': collegeName.trim(),
        'email_address': emailAddress.trim(),
        'event_title': event.title,
        'event_venue': event.venue,
        'event_type': event.runtimeType.toString(),
        'registered_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode != 201) {
      final String errorMsg =
          'Registration failed (${response.statusCode}): ${response.body}';
      print('❌ $errorMsg');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${response.statusCode} - ${response.body}'),
          duration: const Duration(seconds: 5),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _showVoucherEmailDialog(FestEvent event) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController emailController = TextEditingController();
    bool isFetching = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setDialogState) {
            return AlertDialog(
              title: const Text('Download Voucher'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter email address';
                    }
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isFetching
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isFetching
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isFetching = true;
                          });

                          final String email = emailController.text.trim();
                          RegistrationData? data;
                          if (_lastRegistration != null &&
                              _lastRegistration!.eventTitle == event.title &&
                              _lastRegistration!.emailAddress.toLowerCase() ==
                                  email.toLowerCase()) {
                            data = _lastRegistration;
                          } else {
                            data = await _fetchRegistrationByEmail(
                              email: email,
                              eventTitle: event.title,
                            );
                          }

                          if (!context.mounted) return;

                          if (data == null) {
                            setDialogState(() {
                              isFetching = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No registration found for this email.',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.of(context).pop();
                          await _downloadVoucher(data);
                        },
                  child: isFetching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Download'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  Future<RegistrationData?> _fetchRegistrationByEmail({
    required String email,
    required String eventTitle,
  }) async {
    final String supabaseUrl = Env.supabaseUrl;
    final String supabaseKey = Env.supabaseKey;

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase credentials are not configured.'),
        ),
      );
      return null;
    }

    final Uri uri = Uri.parse(
      '$supabaseUrl/rest/v1/registrations'
      '?email_address=eq.${Uri.encodeQueryComponent(email)}'
      '&event_title=eq.${Uri.encodeQueryComponent(eventTitle)}'
      '&order=registered_at.desc&limit=1',
    );
    final http.Response response = await http.get(
      uri,
      headers: <String, String>{
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );

    if (response.statusCode != 200) return null;

    final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
    if (rows.isEmpty) return null;

    final Map<String, dynamic> row = rows.first as Map<String, dynamic>;
    return RegistrationData(
      studentName: row['student_name'] as String? ?? '',
      phoneNumber: row['phone_number'] as String? ?? '',
      collegeName: row['college'] as String? ?? '',
      emailAddress: row['email_address'] as String? ?? '',
      eventTitle: row['event_title'] as String? ?? eventTitle,
      eventVenue: row['event_venue'] as String? ?? '',
      eventType: row['event_type'] as String? ?? '',
      registeredAt:
          DateTime.tryParse(row['registered_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  Future<Uint8List> _buildVoucherPdf(RegistrationData data) async {
    final pw.Font base = await PdfGoogleFonts.robotoRegular();
    final pw.Font bold = await PdfGoogleFonts.robotoBold();
    final pw.Document pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'Fest Voucher Ticket',
                style: const pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text(
                data.eventTitle,
                style: const pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Venue: ${data.eventVenue}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Type: ${data.eventType}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Registrant Information',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Name: ${data.studentName}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'College: ${data.collegeName}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Phone: ${data.phoneNumber}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Email: ${data.emailAddress}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Registered on: ${data.registeredAt.toLocal()}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
              pw.Spacer(),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Text(
                  'Present this voucher at event entry.',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return pdf.save();
  }

  Future<void> _downloadVoucher(RegistrationData data) async {
    try {
      final Uint8List bytes = await _buildVoucherPdf(data);
      final String filename =
          'voucher_${data.eventTitle.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => bytes,
        name: filename,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Voucher preview opened. Use print/save to export PDF.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create voucher: $error')),
      );
    }
  }
}

class EventDetailPage extends StatelessWidget {
  final FestEvent event;
  final VoidCallback? onDownloadVoucher;

  const EventDetailPage({
    super.key,
    required this.event,
    this.onDownloadVoucher,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: const Color.fromARGB(255, 58, 183, 177),
        foregroundColor: const Color.fromARGB(255, 14, 13, 13),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha((0.12 * 255).round()),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/event_landscape_1.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                cacheWidth:
                    (MediaQuery.sizeOf(context).width *
                            MediaQuery.devicePixelRatioOf(context))
                        .round(),
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) => const ColoredBox(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.locationInfo,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.getEventDetails(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (event is CulturalEvent) ...<Widget>[
                    Text(
                      'Category: ${(event as CulturalEvent).category}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Voucher ticket: ${(event is Certifiable && (event as Certifiable).offersCertificate) ? 'Available' : 'Not available'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (event is Certifiable &&
                      (event as Certifiable).offersCertificate) ...<Widget>[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download Voucher'),
                      onPressed: onDownloadVoucher,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Event Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This page shows details of the selected fest event with a preview image and a summary of what to expect. Use this screen to review the venue, status, and special notes before joining the event.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
