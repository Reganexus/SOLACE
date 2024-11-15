import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class DoctorTasks extends StatefulWidget {

  const DoctorTasks({super.key});

  @override
  DoctorTasksState createState() => DoctorTasksState();
}

class DoctorTasksState extends State<DoctorTasks> {

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
