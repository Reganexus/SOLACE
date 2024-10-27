import 'package:solace/screens/home/home.dart';
import 'package:solace/services/auth.dart';
import 'package:flutter/material.dart';

class LogIn extends StatefulWidget {
  final toggleView;
  final bool isTesting;
  final bool isTestAdmin;
  const LogIn({super.key, this.toggleView, required this.isTesting, required this.isTestAdmin });

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {

  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String error = '';

  @override
  void initState() {
    super.initState();
    if (widget.isTesting) {
      _autoLogin();
    }
  }

  Future<void> _autoLogin() async {
    String testEmail = widget.isTestAdmin ? 'earl@gmail.com' : 'john@gmail.com';
    String testPassword = 'test123';

    dynamic result = await _auth.logInWithEmailAndPassword(testEmail, testPassword);
    if (result == null) {
      setState(() => error = 'Could not log in with those credentials');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[100],
      appBar: AppBar(
        backgroundColor: Colors.purple[400],
        elevation: 0.0,
        title: const Text('Log in to SOLACE'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 20.0),
              TextFormField(  // email field
                decoration: InputDecoration(labelText: 'Enter your Email'),
                validator: (val) => val!.isEmpty ? "Enter an email" : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              SizedBox(height: 20.0),
              TextFormField(  // password field
                decoration: InputDecoration(labelText: 'Enter your Password'),
                validator: (val) => val!.length < 6 ? "Enter a password 6+ chars long" : null,
                obscureText: true,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton( // log in button
                onPressed: () async {
                  if(_formKey.currentState!.validate()){
                    dynamic result = await _auth.logInWithEmailAndPassword(email, password);
                    if(result == null) {
                      setState(() => error = 'Could not log in with those credentials');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent[400],
                ),
                child: Text(
                  'Log In',
                  style: TextStyle(
                    color: Colors.tealAccent[800],
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton( // log in button
                onPressed: () {
                  // Navigator.of(context).pushReplacement(
                  // MaterialPageRoute(
                  //   builder: (context) => const SignUp(),
                  // ));
                  widget.toggleView();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent[400],
                ),
                child: Text(
                  'Go to Sign Up page',
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
