import 'package:flutter/material.dart';
import 'package:carbon_counter/screens/carbon_data_screen.dart';
import 'package:carbon_counter/screens/alerts_screen.dart';
import 'package:carbon_counter/screens/account_screen.dart';
import 'package:carbon_counter/widgets/glassmorphic_bottom_bar.dart';

class NavigationContainer extends StatefulWidget {
  const NavigationContainer({Key? key}) : super(key: key);

  @override
  State<NavigationContainer> createState() => _NavigationContainerState();
}

class _NavigationContainerState extends State<NavigationContainer> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CarbonDataScreen(),
    const AlertsScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassmorphicBottomBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}