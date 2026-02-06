import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:pjp_app/calculator/calculator.dart';

final headers = [
  const FHeader(title: Text('Risk Calculator')),
  const FHeader(title: Text('About')),
  const FHeader(title: Text('Contact Us')),
];

final contents = [
  Calculator(),
  const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Text('Categories Placeholder')],
  ),
  const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Text('Search Placeholder')],
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => FScaffold(
    header: headers[_index],
    footer: FBottomNavigationBar(
      index: _index,
      onChange: (index) => setState(() => _index = index),
      children: const [
        FBottomNavigationBarItem(
          icon: Icon(FIcons.calculator),
          label: Text('Calculator'),
        ),
        FBottomNavigationBarItem(
          icon: Icon(FIcons.badgeQuestionMark),
          label: Text('About'),
        ),
        FBottomNavigationBarItem(
          icon: Icon(FIcons.mail),
          label: Text('Contact Us'),
        ),
      ],
    ),
    child: contents[_index],
  );
}
