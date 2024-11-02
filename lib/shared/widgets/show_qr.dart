import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:solace/themes/colors.dart';

class ShowQrPage extends StatelessWidget {
  final String fullName;
  final String uid;

  const ShowQrPage({
    super.key,
    required this.fullName,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('QR Code'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        elevation: 0.0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: AppColors.white,
        ),
        child: SafeArea(
          child: Stack(
            alignment: AlignmentDirectional.topCenter,
            children: [
              Positioned(
                top: 150,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 400,
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: QrImageView(
                          data: uid,
                          version: QrVersions.auto,
                          size: 200.0,
                          gapless: false,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              fullName,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 90,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    image: DecorationImage(
                      image: AssetImage(
                          'lib/assets/images/shared/placeholder.png'), // Placeholder image
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     backgroundColor: AppColors.white,
//     appBar: AppBar(
//       title: const Text('QR Code'),
//       backgroundColor: AppColors.white,
//       scrolledUnderElevation: 0.0,
//       elevation: 0.0,
//     ),
//     body: Container(
//       color: AppColors.white,
//       padding: EdgeInsets.all(30),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Center(
//             child: Container(
//               width: 150,
//               height: 150,
//               decoration: const BoxDecoration(
//                 borderRadius: BorderRadius.all(Radius.circular(50)),
//                 image: DecorationImage(
//                   image: AssetImage(
//                       'lib/assets/images/shared/placeholder.png'), // Placeholder image
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10), // Space after image
//
//           Center(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   fullName,
//                   style: TextStyle(
//                     fontSize: 18.0,
//                     fontWeight: FontWeight.bold,
//                     fontFamily: 'Inter',
//                     color: Colors.black,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
//           Center(
//             child: QrImageView(
//               data: uid,
//               version: QrVersions.auto,
//               size: 200.0,
//               gapless: false,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
