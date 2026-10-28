import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String backendUrl = 'http://localhost:3000';
const String savedSessionTokenKey = 'saved_session_token';
const String savedSessionUsernameKey = 'saved_session_username';

void main() {
  runApp(const SmartHomeApp());
}

String _eventsCacheKey(String username) =>
    'cached_events_${username.toLowerCase()}';

String _imageCacheKey(String username, String eventId) =>
    'cached_image_${username.toLowerCase()}_$eventId';

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Security',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  String? savedToken;
  String? savedUsername;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(savedSessionTokenKey);
    final username = prefs.getString(savedSessionUsernameKey);

    if (!mounted) return;

    setState(() {
      if (token != null &&
          token.isNotEmpty &&
          username != null &&
          username.isNotEmpty) {
        savedToken = token;
        savedUsername = username;
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (savedToken != null && savedUsername != null) {
      return SecurityHomePage(
        token: savedToken!,
        username: savedUsername!,
      );
    }

    return const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  String _errorMessage = '';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': _identifierController.text.trim(),
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        final username = responseData['user']['username'];

        if (token is! String || token.isEmpty) {
          setState(() {
            _errorMessage =
                'The server did not return an authentication token.';
            _isLoggingIn = false;
          });
          return;
        }

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(savedSessionTokenKey, token);
        await prefs.setString(
          savedSessionUsernameKey,
          username.toString(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SecurityHomePage(
              token: token,
              username: username.toString(),
            ),
          ),
        );
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Incorrect username/email or password.';
          _isLoggingIn = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
          _isLoggingIn = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Could not connect to the backend. Make sure the server is running.';
        _isLoggingIn = false;
      });
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Smart Home Security',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to monitor your home',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your login information below.',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email or username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your username or email.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!_isLoggingIn) _login();
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password.';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 50,
                              child: FilledButton(
                                onPressed: _isLoggingIn ? null : _login,
                                child: _isLoggingIn
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Local smart home monitoring',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
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

class SecurityHomePage extends StatefulWidget {
  final String token;
  final String username;

  const SecurityHomePage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<SecurityHomePage> createState() => _SecurityHomePageState();
}

class _SecurityHomePageState extends State<SecurityHomePage> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;
  bool isRefreshing = false;
  bool isOffline = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCacheThenRefresh();
  }

  Future<void> _loadCacheThenRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEvents = prefs.getString(_eventsCacheKey(widget.username));

    if (savedEvents != null) {
      try {
        final decoded = jsonDecode(savedEvents);
        if (decoded is List) {
          events = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      } catch (_) {
        events = [];
      }
    }

    if (mounted) {
      setState(() {
        isLoading = events.isEmpty;
      });
    }

    await fetchEvents();
  }

  Future<void> fetchEvents() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse('$backendUrl/api/events'),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List) {
          final freshEvents = responseData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          final eventsToKeep = freshEvents.take(20).toList();

          await prefs.setString(
            _eventsCacheKey(widget.username),
            jsonEncode(eventsToKeep),
          );

          setState(() {
            events = eventsToKeep;
            isOffline = false;
            isLoading = false;
            isRefreshing = false;
          });

          _cacheImages(eventsToKeep);
        } else {
          setState(() {
            errorMessage = 'The server returned an unexpected response.';
            isLoading = false;
            isRefreshing = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Your session expired. Please log in again.';
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        setState(() {
          isOffline = true;
          errorMessage =
              'Could not refresh. Showing saved events if available.';
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isOffline = true;
        errorMessage =
            'Backend unavailable. Showing saved events if available.';
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _cacheImages(
    List<Map<String, dynamic>> eventList,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    for (final event in eventList) {
      final id = event['id']?.toString();
      final imagePath = event['image_path']?.toString();

      if (id == null ||
          id.isEmpty ||
          imagePath == null ||
          imagePath.isEmpty ||
          prefs.containsKey(_imageCacheKey(widget.username, id))) {
        continue;
      }

      try {
        final response = await http
            .get(
              Uri.parse('$backendUrl/api/events/$id/image'),
              headers: {
                'Authorization': 'Bearer ${widget.token}',
              },
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 &&
            response.bodyBytes.length <= 150000) {
          await prefs.setString(
            _imageCacheKey(widget.username, id),
            base64Encode(response.bodyBytes),
          );
        }
      } catch (_) {
        // Image caching is best-effort. Event loading should still work.
      }
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp.toString().isEmpty) {
      return 'No timestamp available';
    }

    try {
      final dateTime = DateTime.parse(timestamp.toString()).toLocal();

      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '${monthNames[dateTime.month - 1]} ${dateTime.day}, '
          '${dateTime.year} • $hour:$minute $period';
    } catch (_) {
      return timestamp.toString();
    }
  }

  void _openEventDetails(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(
          event: event,
          token: widget.token,
          username: widget.username,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    final prefix = 'cached_image_${widget.username.toLowerCase()}_';

    for (final key in prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .toList()) {
      await prefs.remove(key);
    }

    await prefs.remove(_eventsCacheKey(widget.username));

    await prefs.remove(savedSessionTokenKey);
    await prefs.remove(savedSessionUsernameKey);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home Security'),
        actions: [
          IconButton(
            onPressed: isRefreshing ? null : fetchEvents,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh security events',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout and clear local cache',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${widget.username}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Security Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Offline mode: showing locally saved information.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            if (errorMessage.isNotEmpty && events.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.deepOrange),
                ),
              ),
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (events.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        errorMessage.isEmpty
                            ? 'No security events found.'
                            : errorMessage,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: isRefreshing ? null : fetchEvents,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchEvents,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.blue,
                            size: 30,
                          ),
                          title: Text(
                            event['event_type']?.toString() ??
                                'Unknown event',
                          ),
                          subtitle: Text(
                            '${event['device_id'] ?? 'Unknown device'}\n'
                            '${formatTimestamp(event['timestamp'])}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openEventDetails(event),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EventDetailsPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final String token;
  final String username;

  const EventDetailsPage({
    super.key,
    required this.event,
    required this.token,
    required this.username,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  List<int>? imageBytes;
  bool isLoadingImage = true;
  bool imageIsOffline = false;

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp.toString().isEmpty) {
      return 'No timestamp available';
    }

    try {
      final dateTime = DateTime.parse(timestamp.toString()).toLocal();

      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '${monthNames[dateTime.month - 1]} ${dateTime.day}, '
          '${dateTime.year} • $hour:$minute $period';
    } catch (_) {
      return timestamp.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final eventId = widget.event['id']?.toString();
    final imagePath = widget.event['image_path']?.toString();

    if (eventId == null ||
        eventId.isEmpty ||
        imagePath == null ||
        imagePath.isEmpty) {
      if (mounted) {
        setState(() => isLoadingImage = false);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedImage =
        prefs.getString(_imageCacheKey(widget.username, eventId));

    if (cachedImage != null) {
      try {
        final bytes = base64Decode(cachedImage);

        if (mounted) {
          setState(() {
            imageBytes = bytes;
            isLoadingImage = false;
          });
        }

        return;
      } catch (_) {
        await prefs.remove(_imageCacheKey(widget.username, eventId));
      }
    }

    try {
      final response = await http
          .get(
            Uri.parse('$backendUrl/api/events/$eventId/image'),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        if (response.bodyBytes.length <= 150000) {
          await prefs.setString(
            _imageCacheKey(widget.username, eventId),
            base64Encode(response.bodyBytes),
          );
        }

        if (mounted) {
          setState(() {
            imageBytes = response.bodyBytes;
            isLoadingImage = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingImage = false;
            imageIsOffline = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoadingImage = false;
          imageIsOffline = true;
        });
      }
    }
  }

  Widget _buildImage() {
    if (widget.event['image_path'] == null ||
        widget.event['image_path'].toString().isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.no_photography_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No image has been uploaded for this event.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (isLoadingImage) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (imageBytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageIsOffline)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Showing saved image.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              Uint8List.fromList(imageBytes!),
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Text('Saved image could not be displayed.');
              },
            ),
          ),
        ],
      );
    }

    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'The image is not available. Open this event while online to save it for offline viewing.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = widget.event['id']?.toString() ?? 'Unavailable';
    final deviceId =
        widget.event['device_id']?.toString() ?? 'Unknown device';
    final eventType =
        widget.event['event_type']?.toString() ?? 'Unknown event';
    final timestamp = formatTimestamp(widget.event['timestamp']);
    final status = widget.event['status']?.toString() ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: Colors.blue,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Security Event',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Event #$eventId',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Chip(
                    avatar: const Icon(
                      Icons.circle,
                      size: 12,
                    ),
                    label: Text(status),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Information',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailRow('Event ID', eventId, Icons.tag),
                  const Divider(height: 1),
                  _detailRow(
                    'Device',
                    deviceId,
                    Icons.camera_alt_outlined,
                  ),
                  const Divider(height: 1),
                  _detailRow(
                    'Event Type',
                    eventType,
                    Icons.notifications_active_outlined,
                  ),
                  const Divider(height: 1),
                  _detailRow(
                    'Date and Time',
                    timestamp,
                    Icons.schedule,
                  ),
                  const Divider(height: 1),
                  _detailRow(
                    'Status',
                    status,
                    Icons.info_outline,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Captured Image',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
