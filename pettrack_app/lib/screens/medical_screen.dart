import 'package:flutter/material.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import '../models/medical_data.dart';
import '../theme/colors.dart';
import '../services/notification_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_box.dart';
import 'dart:math';

class MedicalScreen extends StatefulWidget {
  final String serverIp;
  final String token;

  const MedicalScreen({super.key, required this.serverIp, required this.token});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen>
    with SingleTickerProviderStateMixin {
  List<Medication> _medications = [];
  List<Vaccine> _vaccines = [];
  bool _loading = true;
  bool _fromCache = false;
  late TabController _tabController;

  final List<Color> _colorOptions = [
    const Color(0xFF4DB6AC), // Teal
    const Color(0xFFE57373), // Red
    const Color(0xFF64B5F6), // Blue
    const Color(0xFFFFB74D), // Orange
    const Color(0xFFBA68C8), // Purple
  ];

  /// Names for the swatches' semantics — a swatch is only a choice if a
  /// screen reader can name it.
  String _colorName(AppLocalizations l10n, Color c) {
    if (c == const Color(0xFF4DB6AC)) return l10n.colorTeal;
    if (c == const Color(0xFFE57373)) return l10n.colorRed;
    if (c == const Color(0xFF64B5F6)) return l10n.colorBlue;
    if (c == const Color(0xFFFFB74D)) return l10n.colorOrange;
    return l10n.colorPurple;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final meds = await MedicalDataManager.loadMedications(widget.serverIp);
    final vacs = await MedicalDataManager.loadVaccines(widget.serverIp);
    if (!mounted) return;
    setState(() {
      _medications = meds.items;
      _vaccines = vacs.items;
      _fromCache = meds.fromCache || vacs.fromCache;
      _loading = false;
    });
  }

  /// Slim banner shown when the lists are the local copy, not the server's.
  Widget _buildCachedBanner(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.medicalCachedNotice,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l10n.tooltipRefresh,
            icon: const Icon(Icons.refresh, size: 18, color: Colors.orange),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  void _showAddMedicationDialog(AppLocalizations l10n) {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final intervalCtrl = TextEditingController(text: "24");
    bool alertEnabled = false;
    Color selectedColor = _colorOptions.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.addMedication),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.medName),
                ),
                TextField(
                  controller: doseCtrl,
                  decoration: InputDecoration(labelText: l10n.dose),
                ),
                TextField(
                  controller: intervalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.alertFrequency,
                    hintText: l10n.alertFrequencyHint,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.cardColor,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _colorOptions.map((c) {
                    return Semantics(
                      button: true,
                      selected: selectedColor == c,
                      label: _colorName(l10n, c),
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == c
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l10n.enableAlert),
                  value: alertEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setDialogState(() => alertEnabled = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final id = Random().nextInt(99999);
                final interval = int.tryParse(intervalCtrl.text) ?? 24;
                final newMed = Medication(
                  id: id.toString(),
                  name: nameCtrl.text,
                  dose: doseCtrl.text,
                  intervalHours: interval,
                  alertEnabled: alertEnabled,
                  colorValue: selectedColor.toARGB32(),
                );

                if (alertEnabled) {
                  await NotificationService().schedulePeriodicNotification(
                    id: id,
                    title: l10n.medTimeTitle,
                    body: l10n.medTimeBody(newMed.name, newMed.dose),
                    intervalHours: interval,
                  );
                }

                _medications.add(newMed);
                await MedicalDataManager.saveMedications(
                  _medications,
                  widget.serverIp,
                );
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l10n.saveMedication),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVaccineDialog(AppLocalizations l10n) {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final nextCtrl = TextEditingController();
    Color selectedColor = _colorOptions.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.addVaccine),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.vacName),
                ),
                TextField(
                  controller: dateCtrl,
                  decoration: InputDecoration(labelText: l10n.dateGiven),
                ),
                TextField(
                  controller: nextCtrl,
                  decoration: InputDecoration(labelText: l10n.nextDue),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.cardColor,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _colorOptions.map((c) {
                    return Semantics(
                      button: true,
                      selected: selectedColor == c,
                      label: _colorName(l10n, c),
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == c
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final newVac = Vaccine(
                  id: Random().nextInt(99999).toString(),
                  name: nameCtrl.text,
                  dateGiven: dateCtrl.text,
                  nextDue: nextCtrl.text,
                  colorValue: selectedColor.toARGB32(),
                );
                _vaccines.add(newVac);
                await MedicalDataManager.saveVaccines(
                  _vaccines,
                  widget.serverIp,
                );
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l10n.saveVaccine),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.navMedical,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopColumnTitle(
    String title,
    IconData icon,
    VoidCallback onAdd,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onAdd,
          tooltip: l10n.tooltipAdd,
          icon: const Icon(Icons.add_circle, color: AppColors.primary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          // Desktop Layout
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDesktopHeader(l10n),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Medications
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2128),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDesktopColumnTitle(
                                  l10n.medications,
                                  Icons.medical_services,
                                  () => _showAddMedicationDialog(l10n),
                                ),
                                const SizedBox(height: 16),
                                Expanded(child: _buildMedicationsTab(l10n)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Vaccines
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2128),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDesktopColumnTitle(
                                  l10n.vaccines,
                                  Icons.vaccines,
                                  () => _showAddVaccineDialog(l10n),
                                ),
                                const SizedBox(height: 16),
                                Expanded(child: _buildVaccinesTab(l10n)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Mobile Layout (legacy)
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(
                  icon: const Icon(Icons.medical_services),
                  text: l10n.medications,
                ),
                Tab(icon: const Icon(Icons.vaccines), text: l10n.vaccines),
              ],
            ),
            body: TabBarView(
              controller: _tabController,
              children: [_buildMedicationsTab(l10n), _buildVaccinesTab(l10n)],
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'medical_fab',
              backgroundColor: AppColors.primary,
              tooltip: l10n.tooltipAdd,
              onPressed: () {
                if (_tabController.index == 0) {
                  _showAddMedicationDialog(l10n);
                } else {
                  _showAddVaccineDialog(l10n);
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        }
      },
    );
  }

  Widget _buildMedicationsTab(AppLocalizations l10n) {
    final Widget content;
    if (_loading) {
      content = ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonBox.tile(height: 108),
          SizedBox(height: 16),
          SkeletonBox.tile(height: 108),
        ],
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _loadData,
        child: _medications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 48),
                  EmptyState(
                    icon: Icons.medical_services_outlined,
                    title: _fromCache
                        ? l10n.medicalCachedNotice
                        : l10n.noMedications,
                    actionLabel: _fromCache ? l10n.retry : l10n.addMedication,
                    onAction: _fromCache
                        ? _loadData
                        : () => _showAddMedicationDialog(l10n),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 80,
                ),
                itemCount: _medications.length,
                itemBuilder: (ctx, i) {
                  final med = _medications[i];
                  final cardColor = Color(med.colorValue);

                  return GestureDetector(
                    onLongPress: () => _deleteMedication(i),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cardColor.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.outline.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cardColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.medical_services,
                                  color: cardColor,
                                  size: 20,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  med.alertEnabled
                                      ? const Icon(
                                          Icons.notifications_active,
                                          color: Colors.orange,
                                          size: 20,
                                        )
                                      : const Icon(
                                          Icons.notifications_off,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                  IconButton(
                                    tooltip: l10n.tooltipDelete,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteMedication(i),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  med.name,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                if (med.dose.isNotEmpty)
                                  Text(
                                    " ${med.dose}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.outline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.everyXHours(med.intervalHours),
                            style: const TextStyle(
                              color: AppColors.outline,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    }

    return Column(
      children: [
        if (!_loading && _fromCache) _buildCachedBanner(l10n),
        Expanded(child: content),
      ],
    );
  }

  Future<void> _deleteMedication(int index) async {
    final med = _medications[index];
    if (med.alertEnabled) {
      await NotificationService().cancelNotification(int.tryParse(med.id) ?? 0);
    }
    setState(() => _medications.removeAt(index));
    await MedicalDataManager.saveMedications(_medications, widget.serverIp);
  }

  Future<void> _deleteVaccine(int index) async {
    setState(() => _vaccines.removeAt(index));
    await MedicalDataManager.saveVaccines(_vaccines, widget.serverIp);
  }

  Widget _buildVaccinesTab(AppLocalizations l10n) {
    final Widget content;
    if (_loading) {
      content = ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonBox.tile(height: 108),
          SizedBox(height: 16),
          SkeletonBox.tile(height: 108),
        ],
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _loadData,
        child: _vaccines.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 48),
                  EmptyState(
                    icon: Icons.vaccines_outlined,
                    title: _fromCache
                        ? l10n.medicalCachedNotice
                        : l10n.noVaccines,
                    actionLabel: _fromCache ? l10n.retry : l10n.addVaccine,
                    onAction: _fromCache
                        ? _loadData
                        : () => _showAddVaccineDialog(l10n),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 80,
                ),
                itemCount: _vaccines.length,
                itemBuilder: (ctx, i) {
                  final vac = _vaccines[i];
                  final cardColor = Color(vac.colorValue);

                  return GestureDetector(
                    onLongPress: () => _deleteVaccine(i),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cardColor.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.outline.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cardColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.vaccines,
                                  color: cardColor,
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.tooltipDelete,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _deleteVaccine(i),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  vac.name,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                if (vac.dateGiven.isNotEmpty)
                                  Text(
                                    " ${vac.dateGiven}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.outline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${l10n.nextDue}: ${vac.nextDue}",
                            style: const TextStyle(
                              color: AppColors.outline,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    }

    return Column(
      children: [
        if (!_loading && _fromCache) _buildCachedBanner(l10n),
        Expanded(child: content),
      ],
    );
  }
}
