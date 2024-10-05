import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dev/form.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Demo Home'),
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
  // final String ldapFilePath = './ldap.txt'; // Replace with your path
  final String loginUrl = 'https://netaccess.iitm.ac.in/account/login';
  final String loginUrl2 = 'https://netaccess.iitm.ac.in/account/index';
  final String approveUrl = 'https://netaccess.iitm.ac.in/account/approve';
  final int defaultDuration = 1; // Default duration in case of failure

  @override
  void initState() {
    super.initState();
    _runNetworkScript();
  }

  Future<void> _runNetworkScript() async {
    try {
      // final ldapLines = await File(ldapFilePath).readAsLines();
      // if (ldapLines.length < 2) {
      //   throw Exception('LDAP file must contain at least two lines.');
      // }

      // final username = ldapLines[0].trim();
      // final password = ldapLines[1].trim();
      // const username = 'me21b065';
      // const password = 'M}k&2hX@y93';
      List<String> credentials = await _getCredentials();
      final username = credentials[0];
      final password = credentials[1];

      final loginResponse = await http.get(
        Uri.parse(loginUrl),
        headers: {
          'Accept': 'application/json',
        },
      );
      if (loginResponse.statusCode != 200) {
        throw Exception('Failed to get login cookies.');
      }
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
      if (loginResponse2.statusCode != 302) throw Exception('Login failed.');

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
        throw Exception('Failed to approve duration.');
      }

    } catch (e) {
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
            const Text('Running Script...'),
            const SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: _runNetworkScript,
              child: const Text('Repeat'),
            )
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
