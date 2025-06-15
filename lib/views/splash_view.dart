// import 'package:flutter/material.dart';

// import 'package:google_fonts/google_fonts.dart';
// import 'dart:async';

// import 'package:exp_ocr/splash_screen.dart';

// class SplashScreen extends StatefulWidget {
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Timer(Duration(seconds: 3), () {});
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF121212), // Dark background
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset(
//               "assets/images/Untitled.png",
//               height: 150,
//             ), // Updated logo path
//             SizedBox(height: 10),
//             Text(
//               "ExpenSense",
//               style: GoogleFonts.inter(
//                 color: Color(0xFF00FFA3), // Modern deep pink shade from palette
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 10),
//             Text(
//               "Track. Save. Grow.",
//               style: GoogleFonts.poppins(
//                 color: Color(0xFF5A5AFF), // Dark Plum text
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 10),
//             Text(
//               "Smart spending starts here.",
//               style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 30),
//             Container(
//               width: 250,
//               height: 50,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF10B981), Color(0xFF00D1FF)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, '/signup');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.transparent,
//                   shadowColor: Colors.transparent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Text(
//                   "Get Started",
//                   style: GoogleFonts.inter(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(Duration(minutes: 2), () {
        Navigator.pushNamed(context, '/signup');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset("assets/images/splash.png", fit: BoxFit.cover),

          // Gradient overlay for better text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Foreground content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Optional: App Icon or Logo above text
                  Image.asset(
                    "assets/images/Untitled.png", // Make sure logo is optimized for contrast
                    height: 100,
                  ),
                  SizedBox(height: 20),

                  Text(
                    "ExpenSense",
                    style: GoogleFonts.inter(
                      color: Color(0xFF00FFA3),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),

                  Text(
                    "Track. Save. Grow.",
                    style: GoogleFonts.poppins(
                      color: Color(0xFF5A5AFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),

                  Text(
                    "Smart spending starts here.",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),

                  // Get Started Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF00D1FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Get Started",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
