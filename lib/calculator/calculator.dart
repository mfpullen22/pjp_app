import "package:flutter/material.dart";
import 'package:forui/forui.dart';

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  int index = 0;
  bool? respSymp;
  bool? ppx;
  bool? adherence;
  bool? hiv;
  String? location;
  String? comorb;
  String? risks;
  String? radiography;
  String? pretestProb;
  bool? bdg;
  String? bdgResult;
  bool? pcr;
  String? pcrSample;
  String? pcrResult;
  String? posttestProb;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FButton(
              style: FButtonStyle.primary(),
              mainAxisSize: MainAxisSize.min,
              onPress: () {},
              child: const Text('Pre-test Prob'),
            ),
            const SizedBox(width: 10),
            FButton(
              style: FButtonStyle.primary(),
              mainAxisSize: MainAxisSize.min,
              onPress: () {},
              child: const Text('Post-test Prob'),
            ),
          ],
        ),
        FCard(
          title: const Text('Pre-test Probability'),
          child: Column(
            children: [
              const FDivider(),
              const FTextField(label: Text('Name'), hint: 'John Renalo'),
              const SizedBox(height: 10),
              const FTextField(label: Text('Email'), hint: 'john@doe.com'),
              const SizedBox(height: 16),
              FButton(child: const Text('Save'), onPress: () {}),
            ],
          ),
        ),
      ],
    );
  }
}
