import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class DoctorUsers extends StatefulWidget {

  const DoctorUsers({super.key});

  @override
  DoctorUsersState createState() => DoctorUsersState();
}

class DoctorUsersState extends State<DoctorUsers> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Text('Admin Dashboard'),
    );
  }
}
