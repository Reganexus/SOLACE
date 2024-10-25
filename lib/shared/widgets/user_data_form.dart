import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';

class UserDataForm extends StatefulWidget {

  final bool isSignUp;
  final UserData? userData;
  final VoidCallback onButtonPressed;

  const UserDataForm({ super.key, required this.isSignUp, this.userData, required this.onButtonPressed });

  @override
  State<UserDataForm> createState() => _UserDataFormState();
}

class _UserDataFormState extends State<UserDataForm> {
  
  // i'm thinking of reusing this widget for initial input before the user goes to the homepage
  // as well as inside the user profile for further edits (only applied to user profile)

  final _formKey = GlobalKey<FormState>();

  String _error = '';
  String? _lastName;
  String? _firstName;
  String? _middleName;
  String? _phoneNumber;
  String? _sex;
  String? _birthMonth;
  String? _birthDay;
  String? _birthYear;

  List<String> sexes = ['Male', 'Female', 'Other'];
  List<String> months = [ 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  List<String> days = List.generate(31, (index) => (1 + index).toString());
  List<String> years = List.generate(
    (DateTime.now().year) - (DateTime.now().year - 120) + 1,
    (index) => ((DateTime.now().year - 120) + index).toString()
  );

  @override
  Widget build(BuildContext context) {
    
    final user = Provider.of<MyUser?>(context);

    return Scaffold(
      backgroundColor: Colors.purple[100],
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(height: 20.0),
                TextFormField(  // last name field
                  initialValue: widget.userData?.lastName,
                  decoration: InputDecoration(labelText: 'Last Name'),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                  onChanged: (val) {
                    setState(() => _lastName = val);
                  },
                ),
                SizedBox(height: 20.0),
                TextFormField(  // first name field
                  initialValue: widget.userData?.firstName,
                  validator: (val) => val!.isEmpty ? "Required" : null,
                  decoration: InputDecoration(labelText: 'First Name'),
                  onChanged: (val) {
                    setState(() => _firstName = val);
                  },
                ),
                SizedBox(height: 20.0),
                TextFormField(  // middle name field (can be null)
                  initialValue: widget.userData?.middleName,
                  decoration: InputDecoration(labelText: 'Middle Name'),
                  onChanged: (val) {
                    setState(() => _middleName = val);
                  },
                ),
                SizedBox(height: 20.0),
                TextFormField(  // phone number field
                  initialValue: widget.userData?.phoneNumber,
                  validator: (val) => val!.length != 11 ? "Required" : null,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  onChanged: (val) {
                    setState(() => _phoneNumber = val);
                  },
                ),
                SizedBox(height: 20.0),
                DropdownButtonFormField(  // sex dropdown
                  value: _sex ?? widget.userData?.sex,
                  items: sexes.map((sex) {
                    return DropdownMenuItem(
                      value: sex,
                      child: Text(sex),
                    );
                  }).toList(),
                  validator: (val) => val == null ? 'Required' : null,
                  onChanged: (val) => setState(() => _sex = val! ),
                  hint: Text('Sex'),
                ),
                SizedBox(height: 20.0),
                DropdownButtonFormField(  // months dropdown
                  value: _birthMonth ?? widget.userData?.birthMonth,
                  items: months.map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
                  validator: (val) => val == null ? 'Required' : null,
                  onChanged: (val) => setState(() => _birthMonth = val ),
                  hint: Text('Birth Month'),
                ),
                SizedBox(height: 20.0),
                DropdownButtonFormField(  // days dropdown
                  value: _birthDay ?? widget.userData?.birthDay,
                  items: days.map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  validator: (val) => val == null ? 'Required' : null,
                  onChanged: (val) => setState(() => _birthDay = val ),
                  hint: Text('Birth Day'),
                ),
                SizedBox(height: 20.0),
                DropdownButtonFormField(  // years dropdown
                  value: _birthYear ?? widget.userData?.birthYear,
                  items: years.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  validator: (val) => val == null ? 'Required' : null,
                  onChanged: (val) => setState(() => _birthYear = val ),
                  hint: Text('Birth Year'),
                ),
                SizedBox(height: 20.0),
                ElevatedButton( // log in button
                  onPressed: widget.isSignUp ? () {}
                  : () async {
                    print(_lastName);
                    print(_firstName);
                    print(_middleName);
                    print(_phoneNumber);
                    print(_sex);
                    print(_birthMonth);
                    print(_birthDay);
                    print(_birthYear);
                    if(_formKey.currentState!.validate()) {
                      print(user?.uid);
                      await DatabaseService(uid: user!.uid).updateUserData(
                        lastName: _lastName,
                        firstName: _firstName,
                        middleName: _middleName,
                        phoneNumber: _phoneNumber,
                        sex: _sex,
                        birthMonth: _birthMonth,
                        birthDay: _birthDay,
                        birthYear: _birthYear);
                      //setState(() => _error = 'Data updated');
                      print(user?.uid);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent[400],
                  ),
                  child: Text(
                    widget.isSignUp ? 'Create account' : 'Update Data',
                    style: TextStyle(
                      color: Colors.tealAccent[800],
                    ),
                  ),
                ),
                SizedBox(height: 12.0),
                Text(
                  _error,
                  style: TextStyle(color: Colors.red, fontSize: 14.0),
                ),
              ],
            ),
          ),
        )
      ),
    );
  }
}