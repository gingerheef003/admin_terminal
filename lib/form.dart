import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class CredentialsForm extends StatefulWidget {
  const CredentialsForm({super.key});

  @override
  State<CredentialsForm> createState() => _CredentialsFormState();
}

class _CredentialsFormState extends State<CredentialsForm> {

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _storeCredentials() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    await _secureStorage.write(key: 'username', value: username);
    await _secureStorage.write(key: 'password', value: password);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credentials stored securely!')),
    );
  }

  Future<void> _getCredentials() async {
    String? username = await _secureStorage.read(key: 'username');
    String? password = await _secureStorage.read(key: 'password');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stored Username: $username\nStored Password: $password')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _storeCredentials,
            child: const Text('Store Credentials'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _getCredentials,
            child: const Text('Get Stored Credentials'),
          ),
        ],
      ),
    );
  }
}