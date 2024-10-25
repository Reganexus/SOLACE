import 'package:flutter/material.dart';
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

  String _email = '';
  String _password = '';
  bool _acceptedTerms = false;
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
                decoration: InputDecoration(labelText: 'Enter a valid Email'),
                validator: (val) => val!.isEmpty ? "Enter an email" : null,
                onChanged: (val) {
                  setState(() => _email = val);
                },
              ),
              SizedBox(height: 20.0),
              TextFormField(  // password field
                decoration: InputDecoration(labelText: 'Create a Password'),
                validator: (val) => val!.length < 6 ? "Enter a password 6+ chars long" : null,
                obscureText: true,
                onChanged: (val) {
                  setState(() => _password = val);
                },
              ),
              SizedBox(height: 20.0),
              CheckboxListTile(
                title: Text("I accept the Terms and Conditions"),
                value: _acceptedTerms,
                onChanged: (val) {
                  setState(() => _acceptedTerms = val!);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SizedBox(height: 20.0),
              ElevatedButton( // sign up button
                onPressed: () async {
                  if(_formKey.currentState!.validate() && _acceptedTerms) {
                    dynamic result = await _auth.signUpWithEmailAndPassword(_email, _password);
                    if(result == null) {
                      setState(() => error = 'Invalid email or password');
                    }
                  } else if (!_acceptedTerms) {
                    setState(() => error = 'You must accept the Terms and Conditions');
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