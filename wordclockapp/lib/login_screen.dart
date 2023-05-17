import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isHidden = true;
  bool _rememberMe = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
    _loadUsernameAndPassword();
  }

  void _loadRememberMe() async {
    String? rememberMe = await _storage.read(key: 'rememberMe');
    if (rememberMe == 'true') {
      setState(() => _rememberMe = rememberMe == 'true');
    }
  }

  void _loadUsernameAndPassword() async {
    String? username = await _storage.read(key: 'email');
    String? password = await _storage.read(key: 'password');
    if (_rememberMe && username != null && password != null) {
      setState(() {
        _emailController.text = username;
        _passwordController.text = password;
        _login();
      });
    }
  }

  void _login() async {
    // Implement login functionality
    if (_rememberMe) {
      await _storage.write(key: 'rememberMe', value: _rememberMe.toString());
      await _storage.write(key: 'email', value: _emailController.text);
      await _storage.write(key: 'password', value: _passwordController.text);
    } else {
      await _storage.delete(key: 'rememberMe');
      await _storage.delete(key: 'email');
      await _storage.delete(key: 'password');
    }
    print(_emailController.text);
    print(_passwordController.text);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.grey, width:2)
                      ),
                      labelText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isHidden,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.grey, width:2)
                      ),
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.security),
                      suffixIcon: InkWell(
                        onTap: _togglePasswordVisibility,
                        child: Icon(
                          _isHidden ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() => _rememberMe = value!);
              },
            ),
            const Text('Remember me'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignUpScreen()),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Sign up'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
