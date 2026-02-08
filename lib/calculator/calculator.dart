import "package:flutter/material.dart";
import 'package:forui/forui.dart';

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  final _key = GlobalKey<FormState>();
  final _sympController = FMultiValueNotifier<String>.radio();
  final _ppxController = FMultiValueNotifier<String>.radio();
  final _adherenceController = FMultiValueNotifier<String>.radio();
  final _hivController = FMultiValueNotifier<String>.radio();
  final _locationController = FMultiValueNotifier<String>.radio();
  final _comorbController = FMultiValueNotifier<String>.radio();
  final _risksController = FMultiValueNotifier<String>();
  /*   final _locationController = FMultiValueNotifier<String>.radio();
  final _comorbController = FMultiValueNotifier<String>.radio(); */

  int index = 0;
  String? respSymp;
  String? ppx;
  String? adherence;
  String? hiv;
  Set<String> location = {}; // Change to Set
  Set<String> comorb = {}; // Change to Set
  Set<String> risks = {};
  String? radiography;
  double? pretestProb;
  bool? bdg;
  String? bdgResult;
  bool? pcr;
  String? pcrSample;
  String? pcrResult;
  double? posttestProb;

  void _calculatePretestProb() {
    final loc = location.firstOrNull;
    final com = comorb.firstOrNull;

    if (loc != null) {
      switch (loc) {
        case 'Africa':
          pretestProb = 22.7;
          break;
        case 'Asia':
          pretestProb = 28.6;
          break;
        case 'Europe':
          pretestProb = 30.5;
          break;
        case 'North America':
          pretestProb = 31.3;
          break;
        case 'South America':
          pretestProb = 20;
          break;
        case 'Oceania':
          pretestProb = 20;
          break;
      }
    } else if (com != null) {
      switch (com) {
        case 'Lymphoproliferative disorder':
          pretestProb = 17.1;
          break;
        case 'Myeloid disorder':
          pretestProb = 14.9;
          break;
        case 'Renal transplant':
          pretestProb = 11.5;
          break;
        case 'Other solid organ transplant':
          pretestProb = 11.5;
          break;
        case 'Stem cell transplant':
          pretestProb = 11.2;
          break;
        case 'Solid malignancy':
          pretestProb = 5;
          break;
        case 'Autoimmune/inflammatory condition or immunomodulator':
          pretestProb = 5;
          break;
      }
    }

    if (pretestProb != null) {
      double pretestProbStep2 = pretestProb! * 20000;
      double pretestProbStep3 = 20000 - pretestProbStep2;
    }
  }

  @override
  void initState() {
    super.initState();

    /*     // Add listener to update state when controller changes
    _sympController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            respSymp = _sympController.value.firstOrNull;
          });
        }
      });
    });

    _ppxController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            ppx = _ppxController.value.firstOrNull;
          });
        }
      });
    });

    _adherenceController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            adherence = _adherenceController.value.firstOrNull;
          });
        }
      });
    });

    _hivController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            hiv = _hivController.value.firstOrNull;
            location = null;
            comorb = null;
            risks = {};
          });
        }
      });
    });

    _locationController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            location = _locationController.value.firstOrNull;
            _calculatePretestProb();
          });
        }
      });
    });

    _comorbController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            comorb = _comorbController.value.firstOrNull;
            _calculatePretestProb();
          });
        }
      });
    }); */

    /*     _sympController.addListener(() {
      setState(() {
        respSymp = _sympController.value.firstOrNull;
      });
    });
    _ppxController.addListener(() {
      setState(() {
        ppx = _ppxController.value.firstOrNull;
      });
    });
    _adherenceController.addListener(() {
      setState(() {
        adherence = _adherenceController.value.firstOrNull;
      });
    });
    _hivController.addListener(() {
      setState(() {
        hiv = _hivController.value.firstOrNull;
        location = {};
        comorb = {};
        risks = {};
      });
    }); */
  }

  @override
  void dispose() {
    _sympController.dispose();
    _ppxController.dispose();
    _adherenceController.dispose();
    _hivController.dispose();
    _locationController.dispose();
    _comorbController.dispose();
    _risksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([
      _sympController,
      _ppxController,
      _adherenceController,
      _hivController,
      _locationController,
      _comorbController,
      _risksController,
    ]);

    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final respSymp = _sympController.value.firstOrNull;
        final ppx = _ppxController.value.firstOrNull;
        final adherence = _adherenceController.value.firstOrNull;
        final hiv = _hivController.value.firstOrNull;
        final location = _locationController.value;
        final comorb = _comorbController.value;
        final risks = _risksController.value;

        return Form(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 20,
              children: [
                FSelectGroup<String>(
                  control: FMultiValueControl.managed(
                    controller: _sympController,
                  ),
                  label: const Text(
                    'Is the patient at risk of PJP and presenting with a respiratory illness?',
                  ),
                  validator: (values) =>
                      values?.isEmpty ?? true ? 'Please select a value.' : null,
                  children: [
                    FSelectGroupItemMixin.radio(
                      value: "Yes",
                      label: const Text('Yes'),
                    ),
                    FSelectGroupItemMixin.radio(
                      value: "No",
                      label: const Text('No'),
                    ),
                  ],
                ),
                respSymp == "No"
                    ? const Text(
                        "Persons without risk factors for PJP and without respiratory symptoms are unlikely to have PJP.",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const SizedBox.shrink(),
                respSymp == "Yes"
                    ? FSelectGroup<String>(
                        control: FMultiValueControl.managed(
                          controller: _ppxController,
                        ),
                        label: const Text(
                          'Is the patient taking PJP prophylaxis?',
                        ),
                        validator: (values) => values?.isEmpty ?? true
                            ? 'Please select a value.'
                            : null,
                        children: [
                          FSelectGroupItemMixin.radio(
                            value: "Yes",
                            label: const Text('Yes'),
                          ),
                          FSelectGroupItemMixin.radio(
                            value: "No",
                            label: const Text('No'),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                if (ppx == "Yes")
                  FSelectGroup<String>(
                    control: FMultiValueControl.managed(
                      controller: _adherenceController,
                    ),
                    label: const Text(
                      'Are there concerns regarding adherence, inappropriate dosing, or absorption of the prophylaxis?',
                    ),
                    validator: (values) => values?.isEmpty ?? true
                        ? 'Please select a value.'
                        : null,
                    children: [
                      FSelectGroupItemMixin.radio(
                        value: "Yes",
                        label: const Text('Yes'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "No",
                        label: const Text('No'),
                      ),
                    ],
                  ),
                if (adherence == "No")
                  const Text(
                    "Persons taking PJP prophylaxis without concerns regarding adherence, dosing, or absorption are unlikely to have PJP.",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (ppx == "No" || (ppx == "Yes" && adherence == "Yes"))
                  FSelectGroup<String>(
                    control: FMultiValueControl.managed(
                      controller: _hivController,
                    ),
                    label: const Text("What is the patient's HIV status?"),
                    validator: (values) => values?.isEmpty ?? true
                        ? 'Please select a value.'
                        : null,
                    children: [
                      FSelectGroupItemMixin.radio(
                        value: "Positive",
                        label: const Text('Positive'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "Negative",
                        label: const Text('Negative'),
                      ),
                    ],
                  ),
                if (hiv == "Positive")
                  FSelectGroup<String>(
                    control: FMultiValueControl.managed(
                      controller: _locationController,
                    ),
                    label: const Text("Where does the patient live?"),
                    validator: (values) => values?.isEmpty ?? true
                        ? 'Please select a value.'
                        : null,
                    children: [
                      FSelectGroupItemMixin.radio(
                        value: "Africa",
                        label: const Text('Africa'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "Asia",
                        label: const Text('Asia'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "Europe",
                        label: const Text('Europe'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "North America",
                        label: const Text('North America'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "South America",
                        label: const Text('South America'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "Oceania",
                        label: const Text('Oceania'),
                      ),
                    ],
                  ),
                if (hiv == "Negative")
                  FSelectGroup<String>(
                    control: FMultiValueControl.managed(
                      controller: _comorbController,
                    ),
                    label: const Text(
                      "What condition predisposes this patient to PJP?",
                    ),
                    validator: (values) => values?.isEmpty ?? true
                        ? 'Please select a value.'
                        : null,
                    children: [
                      FSelectGroupItemMixin.radio(
                        value: "Lymphoproliferative disorder",
                        label: const Text('Lymphoproliferative disorder'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "Myeloid disorder",
                        label: const Text('Myeloid disorder'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "Renal transplant",
                        label: const Text('Renal transplant'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "Other solid organ transplant",
                        label: const Text('Other solid organ transplant'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "Stem cell transplant",
                        label: const Text('Stem cell transplant'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value: "Solid malignancy",
                        label: const Text('Solid malignancy'),
                      ),
                      FSelectGroupItemMixin.radio(
                        value:
                            "Autoimmune/inflammatory condition or immunomodulator",
                        label: const Text(
                          'Autoimmune/inflammatory condition or immunomodulator',
                        ),
                      ),
                    ],
                  ),
                if (location.isNotEmpty || comorb.isNotEmpty)
                  FSelectTileGroup(
                    label: const Text(
                      "What other risk factors for PJP does this patient have?",
                    ),
                    control: FMultiValueControl.managed(
                      controller: _risksController,
                    ),
                    children: [
                      FSelectTile(
                        title: Text("CMV or BK virus co-infection"),
                        value: "CMV/BK",
                      ),
                      FSelectTile(
                        title: Text("Acute graft rejection"),
                        value: "Acute graft rejection",
                      ),
                      FSelectTile(
                        title: Text("Acute renal dysfunction"),
                        value: "Acute renal dysfunction",
                      ),
                      FSelectTile(
                        title: Text("ABO Mismatch"),
                        value: "ABO Mismatch",
                      ),
                      FSelectTile(
                        title: Text("Diabetes mellitus"),
                        value: "Diabetes mellitus",
                      ),
                      FSelectTile(
                        title: Text("High-dose or longterm corticosteroid use"),
                        value: "Steroids",
                      ),
                      FSelectTile(
                        title: Text("Immunomodulators (biologics, DMARDs"),
                        value: "Immunomodulators",
                      ),
                      FSelectTile(
                        title: Text("Chemotherapy"),
                        value: "Chemotherapy",
                      ),
                      FSelectTile(
                        title: Text("Immunotherapy"),
                        value: "Immunotherapy",
                      ),
                      FSelectTile(
                        title: Text("Elevated LDH"),
                        value: "Elevated LDH",
                      ),
                      FSelectTile(
                        title: Text("Lymphopenia"),
                        value: "Lymphopenia",
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/*
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
          title: Center(child: const Text('Pre-test Probability')),
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
    */
