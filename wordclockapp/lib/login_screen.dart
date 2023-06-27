import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'reusable_widgets/reusable_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginScreen extends StatefulWidget {
  @override
  final bool ignoreRememberMe;
  const LoginScreen({Key? key, required this.ignoreRememberMe}) : super(key: key);
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isHidden = true;
  bool _rememberMe = false;
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String _errorMessage = '';
  @override
  void initState() {
    super.initState();
    if (! widget.ignoreRememberMe) {
      _loadRememberMe();
      _loadUsernameAndPassword();
    }
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
    String email = _emailController.text;
    String password = _passwordController.text;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      _errorMessage = '';
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>
      const HomeScreen()), (Route<dynamic> route) => false);

    } on FirebaseAuthException catch (e) {
      String errorCode = e.code;
        switch (errorCode) {
          case 'invalid-email':
            _errorMessage = 'Invalid email format';
            break;
          case 'user-not-found':
            _errorMessage = 'Wrong credentials try again';
            break;
          case 'user-disabled':
            _errorMessage = 'User account has been disabled';
            break;
          case 'wrong-password':
            _errorMessage = 'Wrong credentials try again';
            break;
          default:
            _errorMessage = e.message!;
      }
      setState(() {});
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log in"),
        backgroundColor: Colors.blueGrey[800],
      ),
      backgroundColor: Colors.blueGrey[300],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: _form,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: <Widget>[
                        reusableTextForm('Email', Icons.email, _emailController),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          controller: _passwordController,
                          obscureText: _isHidden,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.grey, width:2)
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            hintText: 'Password',
                            hintStyle: const TextStyle(
                              color: Colors.black54,
                            ),
                            prefixIcon: const Icon(Icons.security,
                                color: Colors.grey
                            ),
                            suffixIcon: InkWell(
                              onTap: _togglePasswordVisibility,
                              child: Icon(
                                _isHidden ? Icons.visibility_off : Icons.visibility, color: Colors.grey
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val != null && val.isEmpty){
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
            ElevatedButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  _login();
                }
                else {
                  _errorMessage = '';
                  setState(() {
                  });
                }
              },
              child: const Text('Login'),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(15.0),
              ),
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            _errorMessage = '';
            _emailController.text = '';
            _passwordController.text = '';
            setState(() {
            });
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
