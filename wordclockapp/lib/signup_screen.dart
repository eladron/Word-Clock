import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'package:flutter/material.dart';
import 'reusable_widgets/reusable_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool passHidden = true;
  bool confPassHidden = true;
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _signUp() {
    // Implement sign-up functionality here

    FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text).then((value) async {
      await FirebaseFirestore.instance.collection("users").doc(value.user!.uid).set( {
        'email': _emailController.text,
        'username': _usernameController.text,
        'devices': [],
      });
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }).onError((error, stackTrace) {
      print("Error ${error.toString()}");
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      passHidden = !passHidden;
    });
  }

  void _toggleConfPasswordVisibility(){
    setState(() {
      confPassHidden = ! confPassHidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Form(key: _form, child: Column(
              children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child:  Column(
                      children: [
                        reusableTextForm('Username', Icons.person, _usernameController),
                        const SizedBox(height: 16.0),
                        reusableTextForm('Email', Icons.email, _emailController),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: passHidden,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.grey, width:2)
                            ),
                            prefixIcon: const Icon(Icons.security),
                            suffixIcon: InkWell(
                              onTap: _togglePasswordVisibility,
                              child: Icon(
                                passHidden ? Icons.visibility_off : Icons.visibility,
                              ),
                            ),
                            labelText: 'Password',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: confPassHidden,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.grey, width:2)
                            ),
                            prefixIcon: const Icon(Icons.security),
                            suffixIcon: InkWell(
                              onTap: _toggleConfPasswordVisibility,
                              child: Icon(
                                confPassHidden ? Icons.visibility_off : Icons.visibility,
                              ),
                            ),
                            labelText: 'Confirm Password',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                                return 'Value should not be empty';
                            }
                            if (value != _passwordController.text) {
                              return 'Confirm password not matching';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    )
                  // Add other widgets like company name and "Sign up" title here
                  ),
                ],
              )
            ),
            Container(
              height: 60,
              width: 130,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)
                  )
                ),
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    _signUp();
                  }
                },
                  child: const Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 15
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

