// lib/widgets/legal_content.dart
import 'package:flutter/material.dart';

/// Defines the content for the Privacy Policy and Terms of Service.
/// Returns a list of widgets to be displayed within a scrollable view.
List<Widget> getLegalContentWidgets(BuildContext context, String type) {
  final titleStyle = Theme.of(context)
      .textTheme
      .titleLarge
      ?.copyWith(fontWeight: FontWeight.bold);
  final headingStyle = Theme.of(context)
      .textTheme
      .titleMedium
      ?.copyWith(fontWeight: FontWeight.w600);
  final bodyStyle = Theme.of(context).textTheme.bodyMedium;
  const double paragraphSpacing = 16.0;

  // --- Common Header ---
  List<Widget> content = [
    Text(
      type == 'privacy' ? 'Privacy Policy' : 'Terms of Service',
      style: titleStyle,
    ),
    const SizedBox(height: paragraphSpacing * 1.5),
    Text(
      'Last Updated: ${DateTime.now().toLocal().toString().split(' ')[0]}', // Example date
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(fontStyle: FontStyle.italic),
    ),
    const Divider(height: paragraphSpacing * 2, thickness: 1),
  ];

  // --- Specific Content based on Type ---
  if (type == 'privacy') {
    content.addAll([
      Text('Introduction', style: headingStyle),
      const SizedBox(height: paragraphSpacing / 2),
      Text(
        'Welcome to Carbon Shodhak! This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.',
        style: bodyStyle,
      ),
      const SizedBox(height: paragraphSpacing),

      Text('Information We Collect', style: headingStyle),
      const SizedBox(height: paragraphSpacing / 2),
      Text(
        'We may collect information about you in a variety of ways. The information we may collect via the Application includes:\n\n'
        '- Personal Data: Personally identifiable information, such as your name, email address, that you voluntarily give to us when choosing to participate in various activities related to the Application, such as registration.\n'
        '- Derivative Data: Information our servers automatically collect when you access the Application, such as your IP address, your browser type, your operating system, your access times, and the pages you have viewed directly before and after accessing the Application.\n'
        '- Data From Social Networks: User information from social networking sites, such as Google, including your name, your social network username, location, gender, birth date, email address, profile picture, and public data for contacts, if you connect your account to such social networks.',
        style: bodyStyle,
      ),
      const SizedBox(height: paragraphSpacing),

      Text('Use of Your Information', style: headingStyle),
      const SizedBox(height: paragraphSpacing / 2),
      Text(
        'Having accurate information about you permits us to provide you with a smooth, efficient, and customized experience. Specifically, we may use information collected about you via the Application to:\n\n'
        '- Create and manage your account.\n'
        '- Email you regarding your account or order.\n'
        '- Enable user-to-user communications.\n'
        '- Generate a personal profile about you to make future visits to the Application more personalized.',
        style: bodyStyle,
      ),
      const SizedBox(height: paragraphSpacing),

      // --- Add more sections as needed ---
      Text('Disclosure of Your Information', style: headingStyle),
      const SizedBox(height: paragraphSpacing),
      Text('Security of Your Information', style: headingStyle),
      const SizedBox(height: paragraphSpacing),
      Text('Policy for Children', style: headingStyle),
      const SizedBox(height: paragraphSpacing),
      Text('Contact Us', style: headingStyle),
    ]);
  } else if (type == 'terms') {
    content.addAll([
      Text('Agreement to Terms', style: headingStyle),
      const SizedBox(height: paragraphSpacing / 2),
      Text(
        'These Terms of Service constitute a legally binding agreement made between you, whether personally or on behalf of an entity (“you”) and Carbon Shodhak (“we,” “us” or “our”), concerning your access to and use of the Carbon Shodhak mobile application as well as any other media form, media channel, mobile website or mobile application related, linked, or otherwise connected thereto (collectively, the “Application”). You agree that by accessing the Application, you have read, understood, and agree to be bound by all of these Terms of Service.',
        style: bodyStyle,
      ),
      const SizedBox(height: paragraphSpacing),

      Text('Intellectual Property Rights', style: headingStyle),
      const SizedBox(height: paragraphSpacing / 2),
      Text(
        'Unless otherwise indicated, the Application is our proprietary property and all source code, databases, functionality, software, website designs, audio, video, text, photographs, and graphics on the Application (collectively, the “Content”) and the trademarks, service marks, and logos contained therein (the “Marks”) are owned or controlled by us or licensed to us, and are protected by copyright and trademark laws and various other intellectual property rights and unfair competition laws of India, foreign jurisdictions, and international conventions.',
        style: bodyStyle,
      ),
      const SizedBox(height: paragraphSpacing),

      Text('User Representations', style: headingStyle),
      const SizedBox(height: paragraphSpacing / 2),
      Text(
        'By using the Application, you represent and warrant that: (1) all registration information you submit will be true, accurate, current, and complete; (2) you will maintain the accuracy of such information and promptly update such registration information as necessary; (3) you have the legal capacity and you agree to comply with these Terms of Service...',
        style: bodyStyle,
      ),
      const SizedBox(height: paragraphSpacing),

      // --- Add more sections as needed ---
      Text('User Registration', style: headingStyle),
      const SizedBox(height: paragraphSpacing),
      Text('Prohibited Activities', style: headingStyle),
      const SizedBox(height: paragraphSpacing),
      Text('Term and Termination', style: headingStyle),
      const SizedBox(height: paragraphSpacing),
      Text('Governing Law', style: headingStyle),
      const SizedBox(height: paragraphSpacing),
      Text('Contact Us', style: headingStyle),
    ]);
  } else {
    // Fallback for unknown type
    content.add(const Text('Content not available.'));
  }

  return content;
}
