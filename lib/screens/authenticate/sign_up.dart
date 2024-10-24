import 'package:flutter/material.dart';
import 'package:solace/screens/authenticate/login.dart';
import 'package:solace/services/auth.dart';

class SignUp extends StatefulWidget {
  final toggleView;
  const SignUp({super.key, this.toggleView});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[100],
      appBar: AppBar(
        backgroundColor: Colors.purple[400],
        elevation: 0.0,
        title: const Text('Sign up to SOLACE'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 20.0),
              TextFormField(  // email field
                validator: (val) => val!.isEmpty ? "Enter an email" : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              SizedBox(height: 20.0),
              TextFormField(  // password field
                validator: (val) => val!.length < 6 ? "Enter a password 6+ chars long" : null,
                obscureText: true,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton( // sign up button
                onPressed: () async {
                  if(_formKey.currentState!.validate()){
                    dynamic result = await _auth.signUpWithEmailAndPassword(email, password);
                    if(result == null) {
                      setState(() => error = 'Invalid email or password');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent[400],
                ),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.tealAccent[800],
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton( // log in button
                onPressed: () {
                  widget.toggleView();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent[400],
                ),
                child: Text(
                  'Go to Log In page',
                  style: TextStyle(
                    color: Colors.tealAccent[800],
                  ),
                ),
              ),
              SizedBox(height: 12.0),
              Text(
                error,
                style: TextStyle(color: Colors.red, fontSize: 14.0),
              ),
            ],
          ),
        )
      ),
    );
  }
}