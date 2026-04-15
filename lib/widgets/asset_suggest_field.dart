import 'dart:async';

import 'package:flutter/material.dart';
import '../services/asset_ai_service.dart';

/// Smart autocomplete field for asset brand/model suggestions
class AssetSuggestField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String fieldType; // 'brand' or 'model'
  final String? brandValue; // Required for 'model' field type
  final String? categoryValue;
  final String? helperText;
  final bool required;
  final Function(List<String>)? onModelSuggestions;
  final Function(List<String>)? onCategorySuggestions;
  final Function(List<String>)? onUsageSuggestions;

  const AssetSuggestField({
    super.key,
    required this.label,
    required this.controller,
    required this.fieldType,
    this.brandValue,
    this.categoryValue,
    this.helperText,
    this.required = false,
    this.onModelSuggestions,
    this.onCategorySuggestions,
    this.onUsageSuggestions,
  });

  @override
  State<AssetSuggestField> createState() => _AssetSuggestFieldState();
}

class _AssetSuggestFieldState extends State<AssetSuggestField> {
  final AssetAiService _aiService = AssetAiService();
  final FocusNode _focusNode = FocusNode();

  final Map<String, Map<String, dynamic>> _cache = {};
  List<String> _suggestions = <String>[];
  bool _isLoading = false;
  bool _hasFocus = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });

    if (_hasFocus && widget.controller.text.trim().isNotEmpty) {
      _onTextChanged();
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty || !mounted) {
      setState(() {
        _suggestions = <String>[];
        _isLoading = false;
      });
      return;
    }

    final cacheKey =
        '${widget.fieldType}|${widget.brandValue ?? ''}|$normalizedQuery';
    final cached = _cache[cacheKey];
    if (cached != null) {
      if (widget.fieldType == 'model') {
        setState(() {
          _suggestions = List<String>.from(cached['models'] ?? <String>[]);
          _isLoading = false;
        });
      } else {
        setState(() {
          _suggestions = List<String>.from(cached['brands'] ?? <String>[]);
          _isLoading = false;
        });
      }
      widget.onCategorySuggestions?.call(
        List<String>.from(cached['categories'] ?? <String>[]),
      );
      widget.onUsageSuggestions?.call(
        List<String>.from(cached['suggestions']?['usage'] ?? <String>[]),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _aiService.suggestAsset(
        brand: widget.fieldType == 'brand'
            ? normalizedQuery
            : widget.brandValue,
        model: widget.fieldType == 'model' ? normalizedQuery : null,
        category: widget.categoryValue,
      );
      _cache[cacheKey] = result;

      if (!mounted) return;
      if (widget.fieldType == 'model') {
        final rawModels = List<String>.from(result['models'] ?? <String>[]);
        final apiModels = rawModels
            .where(
              (model) =>
                  model.toLowerCase().contains(normalizedQuery.toLowerCase()),
            )
            .toList();
        setState(() {
          _suggestions = apiModels;
          _isLoading = false;
        });
        widget.onModelSuggestions?.call(apiModels);
      } else {
        final apiBrands = List<String>.from(result['brands'] ?? <String>[])
            .where(
              (item) =>
                  item.toLowerCase().contains(normalizedQuery.toLowerCase()),
            )
            .toList();
        setState(() {
          _suggestions = apiBrands;
          _isLoading = false;
        });
        widget.onModelSuggestions?.call(apiBrands);
      }

      widget.onCategorySuggestions?.call(
        List<String>.from(result['categories'] ?? <String>[]),
      );
      widget.onUsageSuggestions?.call(
        List<String>.from(result['suggestions']?['usage'] ?? <String>[]),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(widget.controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              validator: (value) {
                if (widget.required &&
                    (value == null || value.trim().isEmpty)) {
                  return '${widget.label} is required';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: widget.label,
                helperText: widget.helperText,
                hintText: widget.fieldType == 'brand'
                    ? 'Type brand (e.g. John Deere)'
                    : 'Type model (e.g. 5075E)',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  widget.fieldType == 'brand'
                      ? Icons.factory
                      : Icons.build_circle,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF229954),
                    width: 2,
                  ),
                ),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.smart_toy_outlined, size: 20),
              ),
            ),
            if (_shouldShowSuggestions()) ...[
              const SizedBox(height: 8),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (BuildContext context, int index) {
                      final option = _suggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(option),
                        onTap: () {
                          widget.controller.text = option;
                          widget.controller.selection = TextSelection.collapsed(
                            offset: option.length,
                          );
                          _suggestions = <String>[];
                          setState(() {});
                          _fetchSuggestions(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  bool _shouldShowSuggestions() {
    final query = widget.controller.text.trim();
    return _hasFocus &&
        !_isLoading &&
        query.isNotEmpty &&
        _suggestions.isNotEmpty;
  }
}
