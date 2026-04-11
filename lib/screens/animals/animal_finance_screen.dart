import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../models/animal.dart';
import '../../services/expense_service.dart';
import '../../utils/constants.dart';
import '../expenses/add_expense_screen.dart';

class AnimalFinanceScreen extends StatefulWidget {
  final Animal animal;
  const AnimalFinanceScreen({super.key, required this.animal});

  @override
  State<AnimalFinanceScreen> createState() => _AnimalFinanceScreenState();
}

class _AnimalFinanceScreenState extends State<AnimalFinanceScreen> {
  final NumberFormat _nf = NumberFormat.currency(symbol: '€', decimalDigits: 2);
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      final data = await ExpenseService.getAnimalFinanceSummary(widget.animal.id);
      setState(() => _summary = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageTint,
      appBar: AppBar(
        title: Text('Finance: ${widget.animal.name}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
          : RefreshIndicator(
              onRefresh: _fetchSummary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCards(),
                    const SizedBox(height: 24),
                    _buildCategoriesChart(),
                    const SizedBox(height: 24),
                    _buildMissingDataHints(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCards() {
    final entryCost = _summary!['origin'] == 'born' ? _summary!['birthCost'] : _summary!['purchasePrice'];
    final totalCost = _summary!['totalCost'];
    final salePrice = _summary!['salePrice'];
    final margin = _summary!['margin'];

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              _summary!['origin'] == 'born' ? 'Birth Cost' : 'Purchase Price', 
              entryCost != null ? _nf.format(entryCost) : '?', 
              Colors.blue
            ),
            const SizedBox(width: 16),
            _buildStatCard('Total Cost', _nf.format(totalCost), Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: margin >= 0 ? [Colors.green.shade400, Colors.green.shade700] : [Colors.red.shade400, Colors.red.shade700]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: (margin >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.animal.status == 'sold' ? 'REALIZED MARGIN' : 'CURRENT COST VS VALUE', 
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(
                _nf.format(margin),
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)
              ),
              if (widget.animal.status == 'sold' && salePrice != null)
                Text('Sold for ${_nf.format(salePrice)}', style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard('Duration', '${_summary!['durationDays']} days', Colors.purple),
            const SizedBox(width: 16),
            _buildStatCard('Cost / Day', _nf.format(_summary!['costPerDay']), Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesChart() {
    final breakdown = _summary!['breakdown'] as Map<String, dynamic>;
    final total = breakdown.values.fold<double>(0.0, (a, b) => a + (b as num));
    
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EXPENSES BREAKDOWN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 16),
          _buildBar('Feed & Nutrition', breakdown['feed'], total, Colors.orange),
          _buildBar('Veterinary', breakdown['vet'], total, Colors.red),
          _buildBar('Medication & Vaccines', breakdown['meds'], total, Colors.blue),
          _buildBar('Equipment & Services', breakdown['equip'], total, Colors.grey),
          _buildBar('Labor', breakdown['labor'], total, Colors.teal),
          _buildBar('Other', breakdown['other'], total, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildBar(String label, dynamic amt, double total, Color color) {
    final amount = (amt as num).toDouble();
    if (amount <= 0) return const SizedBox.shrink();
    final pct = amount / total;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${_nf.format(amount)} (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingDataHints() {
    final entryCost = _summary!['origin'] == 'born' ? _summary!['birthCost'] : _summary!['purchasePrice'];
    List<Widget> hints = [];

    if (entryCost == null) {
      hints.add(
        _buildHint(
          icon: Symbols.warning,
          color: Colors.orange,
          msg: _summary!['origin'] == 'born' ? 'Birth cost is missing. Margin calculation is incomplete.' : 'Purchase price is missing. Margin calculation is incomplete.',
        )
      );
    }
    
    final breakdown = _summary!['breakdown'] as Map<String, dynamic>;
    final total = breakdown.values.fold<double>(0.0, (a, b) => a + (b as num));
    
    if (total == 0) {
      hints.add(
        _buildHint(
          icon: Symbols.info,
          color: Colors.blue,
          msg: 'No expenses tracked yet for this animal.',
        )
      );
    }

    if (hints.isEmpty) return const SizedBox.shrink();

    return Column(children: hints);
  }

  Widget _buildHint({required IconData icon, required Color color, required String msg}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: TextStyle(color: color.withAlpha(200), fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
