import "package:flutter/material.dart";
import "package:forui/forui.dart";

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  final _key = GlobalKey<FormState>();

  // Single-select controllers
  final _sympController = FMultiValueNotifier<String>.radio();
  final _ppxController = FMultiValueNotifier<String>.radio();
  final _adherenceController = FMultiValueNotifier<String>.radio();
  final _hivController = FMultiValueNotifier<String>.radio();
  final _locationController = FMultiValueNotifier<String>.radio();
  final _comorbController = FMultiValueNotifier<String>.radio();
  final _radiographyController = FMultiValueNotifier<String>.radio();

  // Multi-select controller
  final _risksController = FMultiValueNotifier<String>();

  // Outputs (store as fractions 0..1)
  double? finalPretestProb;

  // Wizard state
  int _stepIndex = 0;

  // Used to avoid recalculating in a loop
  String? _lastCalcSignature;

  void _resetCalculator() {
    _sympController.value = {};
    _ppxController.value = {};
    _adherenceController.value = {};
    _hivController.value = {};
    _locationController.value = {};
    _comorbController.value = {};
    _risksController.value = {};
    _radiographyController.value = {};

    setState(() {
      _stepIndex = 0;
      finalPretestProb = null;
      _lastCalcSignature = null;
    });
  }

  String _highestRisk(Set<String> selected) {
    const priority = <String>[
      "Immunotherapy",
      "Elevated LDH",
      "CMV/BK",
      "ABO Mismatch",
      "Acute renal dysfunction",
      "Acute graft rejection",
      "Diabetes mellitus",
      "Lymphopenia",
      "Chemotherapy",
      "Steroids",
      "Immunomodulators",
      "None",
    ];

    for (final item in priority) {
      if (selected.contains(item)) return item;
    }
    return "None";
  }

  /// Pure-ish calculator: returns final pretest probability as fraction (0..1),
  /// or null if required inputs are missing.
  double? _computeFinalPretestProb() {
    final loc = _locationController.value.firstOrNull;
    final com = _comorbController.value.firstOrNull;

    // Base as fraction
    double? base;
    if (loc != null) {
      switch (loc) {
        case "Africa":
          base = 0.227;
          break;
        case "Asia":
          base = 0.286;
          break;
        case "Europe":
          base = 0.305;
          break;
        case "North America":
          base = 0.313;
          break;
        case "South America":
          base = 0.20;
          break;
        case "Oceania":
          base = 0.20;
          break;
      }
    } else if (com != null) {
      switch (com) {
        case "Lymphoproliferative disorder":
          base = 0.171;
          break;
        case "Myeloid disorder":
          base = 0.149;
          break;
        case "Renal transplant":
          base = 0.115;
          break;
        case "Other solid organ transplant":
          base = 0.115;
          break;
        case "Stem cell transplant":
          base = 0.112;
          break;
        case "Solid malignancy":
          base = 0.05;
          break;
        case "Autoimmune/inflammatory condition or immunomodulator":
          base = 0.05;
          break;
      }
    }

    if (base == null) return null;

    // Risk-factor adjustment (still fraction)
    final topRisk = _highestRisk(_risksController.value);
    double prelim = base;

    if (topRisk != "None") {
      final step2 = base * 20000;
      final step3 = 20000 - step2;

      final riskParams = <String, (double value1, double value2)>{
        "Immunotherapy": (0.1538, 0.9688),
        "Elevated LDH": (0.383, 0.90),
        "CMV/BK": (0.359, 0.903),
        "ABO Mismatch": (0.2901, 0.9147),
        "Acute renal dysfunction": (0.4528, 0.8469),
        "Acute graft rejection": (0.387, 0.808),
        "Diabetes mellitus": (0.493, 0.718),
        "Lymphopenia": (0.717, 0.53),
        "Chemotherapy": (0.15, 0.888),
        "Steroids": (0.40, 0.566),
        "Immunomodulators": (0.128, 0.706),
      };

      final params = riskParams[topRisk];
      if (params != null) {
        final value1 = params.$1;
        final value2 = params.$2;

        final truePos = value1 * step2;
        final trueNeg = value2 * step3;
        final falsePos = step3 - trueNeg;

        final denom = truePos + falsePos;
        prelim = denom == 0 ? 0 : (truePos / denom);
      }
    }

    // Radiography adjustment (still fraction)
    final rad = _radiographyController.value.firstOrNull;
    double finalVal = prelim;

    if (rad != null && rad != "None or unknown") {
      final radStep2 = prelim * 20000;
      final radStep3 = 20000 - radStep2;

      final (sens, spec) = switch (rad) {
        "Groundglass opacities" => (0.719, 0.551),
        "Non-groundglass opacities" => (0.571, 0.814),
        _ => (0.0, 0.0),
      };

      final radTruePos = radStep2 * sens;
      final radTrueNeg = radStep3 * spec;
      final radFalsePos = radStep3 - radTrueNeg;

      final denom = radTruePos + radFalsePos;
      finalVal = denom == 0 ? 0 : (radTruePos / denom);
    }

    return finalVal;
  }

  /// Generates a stable signature of current inputs so we only recalc when needed.
  String _calcSignature() {
    final loc = _locationController.value.firstOrNull ?? "";
    final com = _comorbController.value.firstOrNull ?? "";
    final rad = _radiographyController.value.firstOrNull ?? "";
    final risksSorted = _risksController.value.toList()..sort();
    return "loc=$loc|com=$com|rad=$rad|risks=${risksSorted.join(",")}";
  }

  void _scheduleAutoCalcIfNeeded() {
    final sig = _calcSignature();
    if (_lastCalcSignature == sig && finalPretestProb != null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final computed = _computeFinalPretestProb();
      setState(() {
        _lastCalcSignature = sig;
        finalPretestProb = computed;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    // If upstream changes, clear result and calc signature.
    void clearResult() {
      setState(() {
        finalPretestProb = null;
        _lastCalcSignature = null;
      });
    }

    _sympController.addListener(() {
      _ppxController.value = {};
      _adherenceController.value = {};
      _hivController.value = {};
      _locationController.value = {};
      _comorbController.value = {};
      _risksController.value = {};
      _radiographyController.value = {};
      setState(() {
        _stepIndex = 0;
        finalPretestProb = null;
        _lastCalcSignature = null;
      });
    });

    _ppxController.addListener(() {
      _adherenceController.value = {};
      _hivController.value = {};
      _locationController.value = {};
      _comorbController.value = {};
      _risksController.value = {};
      _radiographyController.value = {};
      clearResult();
    });

    _adherenceController.addListener(() {
      _hivController.value = {};
      _locationController.value = {};
      _comorbController.value = {};
      _risksController.value = {};
      _radiographyController.value = {};
      clearResult();
    });

    _hivController.addListener(() {
      _locationController.value = {};
      _comorbController.value = {};
      _risksController.value = {};
      _radiographyController.value = {};
      clearResult();
    });

    _locationController.addListener(() {
      if (_locationController.value.isNotEmpty) _comorbController.value = {};
      _risksController.value = {};
      _radiographyController.value = {};
      clearResult();
    });

    _comorbController.addListener(() {
      if (_comorbController.value.isNotEmpty) _locationController.value = {};
      _risksController.value = {};
      _radiographyController.value = {};
      clearResult();
    });

    _risksController.addListener(() {
      if (_risksController.value.isEmpty &&
          _radiographyController.value.isNotEmpty) {
        _radiographyController.value = {};
      }
      clearResult();
    });

    _radiographyController.addListener(clearResult);
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
    _radiographyController.dispose();
    super.dispose();
  }

  List<_WizardStep> _buildSteps({
    required String? respSymp,
    required String? ppx,
    required String? adherence,
    required String? hiv,
    required bool hasLocOrComorb,
    required bool hasRisks,
    required bool hasRadiography,
  }) {
    final steps = <_WizardStep>[];

    steps.add(
      _WizardStep(
        title: "Symptoms",
        canProceed: respSymp != null,
        contentBuilder: () => FSelectGroup<String>(
          control: FMultiValueControl.managed(controller: _sympController),
          label: const Text("Respiratory symptoms + at-risk for PJP?"),
          children: [
            FSelectGroupItemMixin.radio(value: "Yes", label: Text("Yes")),
            FSelectGroupItemMixin.radio(value: "No", label: Text("No")),
          ],
        ),
        hint: respSymp == "No"
            ? "Without risk factors and respiratory symptoms, PJP is unlikely."
            : null,
        hintIsWarning: respSymp == "No",
      ),
    );

    if (respSymp == "No") return steps;

    steps.add(
      _WizardStep(
        title: "Prophylaxis",
        canProceed: ppx != null,
        contentBuilder: () => FSelectGroup<String>(
          control: FMultiValueControl.managed(controller: _ppxController),
          label: const Text("Taking PJP prophylaxis?"),
          children: [
            FSelectGroupItemMixin.radio(value: "Yes", label: Text("Yes")),
            FSelectGroupItemMixin.radio(value: "No", label: Text("No")),
          ],
        ),
      ),
    );

    if (ppx == "Yes") {
      steps.add(
        _WizardStep(
          title: "Adherence",
          canProceed: adherence != null,
          contentBuilder: () => FSelectGroup<String>(
            control: FMultiValueControl.managed(
              controller: _adherenceController,
            ),
            label: const Text("Concerns about adherence, dosing, absorption?"),
            children: [
              FSelectGroupItemMixin.radio(value: "Yes", label: Text("Yes")),
              FSelectGroupItemMixin.radio(value: "No", label: Text("No")),
            ],
          ),
          hint: adherence == "No"
              ? "Prophylaxis without adherence/dosing concerns makes PJP unlikely."
              : null,
          hintIsWarning: adherence == "No",
        ),
      );

      if (adherence == "No") return steps;
    }

    steps.add(
      _WizardStep(
        title: "HIV status",
        canProceed: hiv != null,
        contentBuilder: () => FSelectGroup<String>(
          control: FMultiValueControl.managed(controller: _hivController),
          label: const Text("HIV status"),
          children: [
            FSelectGroupItemMixin.radio(
              value: "Positive",
              label: Text("Positive"),
            ),
            FSelectGroupItemMixin.radio(
              value: "Negative",
              label: Text("Negative"),
            ),
          ],
        ),
      ),
    );

    if (hiv == "Positive") {
      steps.add(
        _WizardStep(
          title: "Region",
          canProceed: _locationController.value.isNotEmpty,
          contentBuilder: () => FSelectGroup<String>(
            control: FMultiValueControl.managed(
              controller: _locationController,
            ),
            label: const Text("Where does the patient live?"),
            children: [
              FSelectGroupItemMixin.radio(
                value: "Africa",
                label: Text("Africa"),
              ),
              FSelectGroupItemMixin.radio(value: "Asia", label: Text("Asia")),
              FSelectGroupItemMixin.radio(
                value: "Europe",
                label: Text("Europe"),
              ),
              FSelectGroupItemMixin.radio(
                value: "North America",
                label: Text("North America"),
              ),
              FSelectGroupItemMixin.radio(
                value: "South America",
                label: Text("South America"),
              ),
              FSelectGroupItemMixin.radio(
                value: "Oceania",
                label: Text("Oceania"),
              ),
            ],
          ),
        ),
      );
    } else if (hiv == "Negative") {
      steps.add(
        _WizardStep(
          title: "Comorbidity",
          canProceed: _comorbController.value.isNotEmpty,
          contentBuilder: () => FSelectGroup<String>(
            control: FMultiValueControl.managed(controller: _comorbController),
            label: const Text("Predisposing condition"),
            children: [
              FSelectGroupItemMixin.radio(
                value: "Lymphoproliferative disorder",
                label: Text("Lymphoproliferative disorder"),
              ),
              FSelectGroupItemMixin.radio(
                value: "Myeloid disorder",
                label: Text("Myeloid disorder"),
              ),
              FSelectGroupItemMixin.radio(
                value: "Renal transplant",
                label: Text("Renal transplant"),
              ),
              FSelectGroupItemMixin.radio(
                value: "Other solid organ transplant",
                label: Text("Other solid organ transplant"),
              ),
              FSelectGroupItemMixin.radio(
                value: "Stem cell transplant",
                label: Text("Stem cell transplant"),
              ),
              FSelectGroupItemMixin.radio(
                value: "Solid malignancy",
                label: Text("Solid malignancy"),
              ),
              FSelectGroupItemMixin.radio(
                value: "Autoimmune/inflammatory condition or immunomodulator",
                label: Text("Autoimmune / inflammatory or immunomodulator"),
              ),
            ],
          ),
        ),
      );
    }

    if (hasLocOrComorb) {
      steps.add(
        _WizardStep(
          title: "Other risks",
          canProceed: hasRisks,
          contentBuilder: () => FSelectTileGroup(
            label: const Text("Other risk factors for PJP"),
            control: FMultiValueControl.managed(controller: _risksController),
            children: const [
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
              FSelectTile(title: Text("ABO Mismatch"), value: "ABO Mismatch"),
              FSelectTile(
                title: Text("Diabetes mellitus"),
                value: "Diabetes mellitus",
              ),
              FSelectTile(
                title: Text("High-dose or longterm corticosteroid use"),
                value: "Steroids",
              ),
              FSelectTile(
                title: Text("Immunomodulators (biologics, DMARDs)"),
                value: "Immunomodulators",
              ),
              FSelectTile(title: Text("Chemotherapy"), value: "Chemotherapy"),
              FSelectTile(title: Text("Immunotherapy"), value: "Immunotherapy"),
              FSelectTile(title: Text("Elevated LDH"), value: "Elevated LDH"),
              FSelectTile(title: Text("Lymphopenia"), value: "Lymphopenia"),
              FSelectTile(title: Text("None"), value: "None"),
            ],
          ),
        ),
      );
    }

    if (hasRisks) {
      steps.add(
        _WizardStep(
          title: "Radiography",
          canProceed: hasRadiography,
          contentBuilder: () => FSelectTileGroup(
            label: const Text("Radiographic changes compatible with PJP?"),
            control: FMultiValueControl.managed(
              controller: _radiographyController,
            ),
            children: const [
              FSelectTile(
                title: Text("Groundglass opacities"),
                value: "Groundglass opacities",
              ),
              FSelectTile(
                title: Text("Non-groundglass opacities"),
                value: "Non-groundglass opacities",
              ),
              FSelectTile(
                title: Text("None or unknown"),
                value: "None or unknown",
              ),
            ],
          ),
        ),
      );

      // Result step
      steps.add(
        _WizardStep(
          title: "Result",
          canProceed: true,
          isResultStep: true,
          contentBuilder: () => Column(
            spacing: 16,
            children: [
              FCard(
                title: const Text("Pre-test Probability"),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FDivider(),
                    Text(
                      finalPretestProb == null
                          ? "Calculating…"
                          : "The pretest probability of PJP infection in this patient is "
                                "${(finalPretestProb! * 100).toStringAsFixed(2)}%",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              FButton(
                style: FButtonStyle.destructive(),
                onPress: _resetCalculator,
                child: const Text("Reset"),
              ),
            ],
          ),
        ),
      );
    }

    return steps;
  }

  void _goNext(int max) {
    setState(() {
      _stepIndex = (_stepIndex + 1).clamp(0, max - 1);
    });
  }

  void _goBack() {
    setState(() {
      _stepIndex = (_stepIndex - 1).clamp(0, 1000);
    });
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
      _radiographyController,
    ]);

    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final respSymp = _sympController.value.firstOrNull;
        final ppx = _ppxController.value.firstOrNull;
        final adherence = _adherenceController.value.firstOrNull;
        final hiv = _hivController.value.firstOrNull;

        final hasLocOrComorb =
            _locationController.value.isNotEmpty ||
            _comorbController.value.isNotEmpty;
        final hasRisks = _risksController.value.isNotEmpty;
        final hasRadiography = _radiographyController.value.isNotEmpty;

        final steps = _buildSteps(
          respSymp: respSymp,
          ppx: ppx,
          adherence: adherence,
          hiv: hiv,
          hasLocOrComorb: hasLocOrComorb,
          hasRisks: hasRisks,
          hasRadiography: hasRadiography,
        );

        // Clamp step when branching shortens flow
        final max = steps.length;
        final current = _stepIndex.clamp(0, max - 1);
        if (current != _stepIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _stepIndex = current);
          });
        }

        final step = steps[current];
        final isLast = current == max - 1;

        // Auto-calc when entering the Result step
        if (step.isResultStep) {
          _scheduleAutoCalcIfNeeded();
        }

        final progress = max <= 1 ? 1.0 : (current + 1) / max;

        return Form(
          key: _key,
          child: SafeArea(
            child: Column(
              children: [
                // Header / progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Step ${current + 1} of $max — ${step.title}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(value: progress),
                      ),
                    ],
                  ),
                ),

                // Step content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      spacing: 14,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FCard(
                          title: Text(step.title),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [const FDivider(), step.contentBuilder()],
                          ),
                        ),
                        if (step.hint != null)
                          Text(
                            step.hint!,
                            style: TextStyle(
                              color: step.hintIsWarning ? Colors.red : null,
                              fontWeight: step.hintIsWarning
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Footer controls (Back/Next) only if not on last step
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: FButton(
                            onPress: current == 0 ? null : _goBack,
                            child: const Text("Back"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FButton(
                            style: FButtonStyle.primary(),
                            onPress: step.canProceed
                                ? () => _goNext(max)
                                : null,
                            child: const Text("Next"),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WizardStep {
  final String title;
  final bool canProceed;
  final Widget Function() contentBuilder;
  final String? hint;
  final bool hintIsWarning;
  final bool isResultStep;

  _WizardStep({
    required this.title,
    required this.canProceed,
    required this.contentBuilder,
    this.hint,
    this.hintIsWarning = false,
    this.isResultStep = false,
  });
}
