import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphicBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassmorphicBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive width - more compact on larger screens
        final maxWidth = constraints.maxWidth;
        final barWidth = maxWidth > 600 ? 400.0 : maxWidth;
        
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: barWidth,
                  height: 56,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withAlpha(30),
                            Colors.white.withAlpha(15),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withAlpha(40),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          splashFactory: NoSplash.splashFactory,
                          highlightColor: Colors.transparent,
                        ),
                        child: BottomNavigationBar(
                          currentIndex: currentIndex,
                          onTap: onTap,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          selectedItemColor: Colors.white,
                          unselectedItemColor: Colors.white.withAlpha(128),
                          type: BottomNavigationBarType.fixed,
                          showSelectedLabels: true,
                          showUnselectedLabels: true,
                          selectedLabelStyle: const TextStyle(fontSize: 12),
                          unselectedLabelStyle: const TextStyle(fontSize: 12),
                          items: const [
                            BottomNavigationBarItem(
                              icon: Icon(Icons.home_rounded),
                              label: 'Home',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.notifications_rounded),
                              label: 'Alerts',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.person_rounded),
                              label: 'Account',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}