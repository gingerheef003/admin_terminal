import 'package:flutter/material.dart';
import 'package:admin_terminal/form.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quick_actions/quick_actions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Script Runner',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Admin Terminal'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String loginUrl = 'https://netaccess.iitm.ac.in/account/login';
  final String approveUrl = 'https://netaccess.iitm.ac.in/account/approve';
  final List<int> checkpoints = [0, 0, 0];
  String time = '';
  String shortcut = 'none';

  @override
  void initState() {
    super.initState();

    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      if(shortcutType == 'netaccess') {
        Future.microtask(() => _runNetworkScript());
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'netaccess', localizedTitle: 'NetAccess', icon: 'ic_wifi')
    ]);
  }

  Future<void> _runNetworkScript() async {
    try {
      setState(() {
        checkpoints.fillRange(0, checkpoints.length, 0);
      });

      List<String> credentials = await _getCredentials();
      final username = credentials[0];
      final password = credentials[1];

      if (username == '' || password == '') {
        throw Exception('No credentials present!!!');
      }

      final loginResponse = await http.get(
        Uri.parse(loginUrl),
        headers: {
          'Accept': 'application/json',
        },
      );
      if (loginResponse.statusCode != 200) {
        setState(() {
          checkpoints[0] = 2;
        });
        throw Exception('Failed to get login cookies.');
      }
      setState(() {
        checkpoints[0] = 1;
      });

      final cookies = loginResponse.headers["set-cookie"];
      final phpSessId = _extractPhpSessId(cookies);

      final loginResponse2 = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': 'PHPSESSID=$phpSessId'
        },
        body: {
          'userLogin': username,
          'userPassword': password,
          'submit': '',
        },
      );
      if (loginResponse2.statusCode != 302) {
        setState(() {
          checkpoints[1] = 2;
        });
        throw Exception('Login failed.');
      }
      setState(() {
        checkpoints[1] = 1;
      });

      const duration = "2";

      final approveResponse = await http.post(
        Uri.parse(approveUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': 'PHPSESSID=$phpSessId'
        },
        body: {
          'duration': duration,
          'approveBtn': '',
        },
      );
      if (approveResponse.statusCode != 302) {
        setState(() {
          checkpoints[2] = 2;
        });
        throw Exception('Failed to approve duration.');
      }

      setState(() {
        time = DateFormat('hh:mm:ss').format(DateTime.now());
        checkpoints[2] = 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      print('Error: $e');
    }
  }

  String _extractPhpSessId(String? cookies) {
    if (cookies == null) return '';
    final cookieList = cookies.split(';');
    for (var cookie in cookieList) {
      final parts = cookie.split('=');
      if (parts.length == 2 && parts[0].trim() == 'PHPSESSID') {
        return parts[1].trim();
      }
    }
    return '';
  }

  final _secureStorage = const FlutterSecureStorage();

  Future<List<String>> _getCredentials() async {
    String? username = await _secureStorage.read(key: 'username');
    String? password = await _secureStorage.read(key: 'password');

    return [username ?? '', password ?? ''];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _runNetworkScript,
              child: const Text('Let there be LIGHT...'),
            ),
            const SizedBox(
              height: 5,
            ),
            if (checkpoints[0] == 1) const Text('Received SessionID'),
            if (checkpoints[1] == 1) const Text('Login Successful'),
            if (checkpoints[2] == 1)
              Text(
                'Netaccessed Successfully at $time',
                style: const TextStyle(color: Colors.green),
              ),
            const SizedBox(
              height: 5,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Add Credentials'),
                  content: const CredentialsForm(),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    )
                  ],
                );
              });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
