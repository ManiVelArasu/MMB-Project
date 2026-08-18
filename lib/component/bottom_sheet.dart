import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:provider/provider.dart';

enum FieldType { text, dropdown, checkbox, radioButton }

class FormFieldConfig {
  final String id;
  final String label;
  final String hint;
  final FieldType type;
  final List<String>? options;
  final bool isRequired;

  FormFieldConfig({
    required this.id,
    required this.label,
    this.hint = "",
    this.type = FieldType.text,
    this.options,
    this.isRequired = true,
  });
}

class DynamicFormBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String title;
  final String subTitle;
  final List<FormFieldConfig> fields;
  final Function(Map<String, dynamic> formValues) onSubmit;

  const DynamicFormBottomSheet({
    super.key,
    required this.scrollController,
    required this.title,
    required this.subTitle,
    required this.fields,
    required this.onSubmit,
  });

  @override
  State<DynamicFormBottomSheet> createState() => _DynamicFormBottomSheetState();
}

class _DynamicFormBottomSheetState extends State<DynamicFormBottomSheet> {
  final Map<String, dynamic> _formValues = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      if (field.type == FieldType.text) {
        _controllers[field.id] = TextEditingController();
      } else if (field.type == FieldType.checkbox) {
        _formValues[field.id] = false;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isFormValid() {
    for (var field in widget.fields) {
      if (field.isRequired) {
        final val = _formValues[field.id];
        if (field.type == FieldType.text) {
          if (val == null || val.toString().trim().isEmpty) return false;
        } else if (field.type == FieldType.checkbox) {
          if (val != true) return false;
        } else {
          if (val == null) return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        color: customColor.whiteColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle & Close Header
            Center(
              child: Container(
                height: 4.h,
                width: 100.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: customColor.greyColor.withAlpha(50),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  widget.title,
                  style: theme.bodyLarge!.copyWith(
                    color: customColor.blackColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: SvgPicture.asset("assets/icons/close_ic.svg"),
                ),
              ],
            ),
            Text(
              widget.subTitle,
              style: theme.bodyMedium!.copyWith(color: customColor.blackColor),
            ),
            SizedBox(height: 16.h),

            // Dynamic Form Fields List
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: widget.fields.length,
                itemBuilder: (context, index) {
                  final field = widget.fields[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _buildFieldWidget(field, customColor, theme),
                  );
                },
              ),
            ),

            height12,

            // Dynamic Action Button
            ButtonWidget(
              buttonPress: () {
                if (_isFormValid()) {
                  widget.onSubmit(_formValues);
                }
              },
              title: "CONTINUE",
              textStyle: theme.titleLarge!.copyWith(
                color: customColor.whiteColor,
                fontWeight: FontWeight.w700,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _isFormValid()
                    ? customColor.redColor
                    : customColor.greyColor.withAlpha(100),
              ),
              height: 54.h,
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldWidget(
    FormFieldConfig field,
    dynamic customColor,
    TextTheme theme,
  ) {
    switch (field.type) {
      case FieldType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: theme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _controllers[field.id],
              onChanged: (val) {
                setState(() {
                  _formValues[field.id] = val;
                });
              },
              decoration: InputDecoration(
                hintText: field.hint,
                hintStyle: theme.bodyMedium!.copyWith(
                  color: customColor.greyColor.withAlpha(80),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
          ],
        );

      case FieldType.dropdown:
        final selectedVal = _formValues[field.id];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: theme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            InkWell(
              onTap: () => _openSelectionModal(field, customColor, theme),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    Text(
                      selectedVal ?? field.hint,
                      style: theme.bodyMedium!.copyWith(
                        color: selectedVal != null
                            ? customColor.blackColor
                            : customColor.greyColor.withAlpha(80),
                        fontWeight: selectedVal != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: customColor.greyColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case FieldType.radioButton:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: theme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Column(
              children: (field.options ?? []).map((option) {
                return RadioListTile<String>(
                  title: Text(option, style: theme.bodyMedium),
                  value: option,
                  groupValue: _formValues[field.id],
                  activeColor: customColor.redColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      _formValues[field.id] = val;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );

      // 4. CHECKBOX FIELD
      case FieldType.checkbox:
        return CheckboxListTile(
          title: Text(field.label, style: theme.bodyMedium),
          value: _formValues[field.id] ?? false,
          activeColor: customColor.redColor,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() {
              _formValues[field.id] = val;
            });
          },
        );
    }
  }

  // Modal Sheet for Searchable Dropdown Options
  void _openSelectionModal(
    FormFieldConfig field,
    dynamic customColor,
    TextTheme theme,
  ) {
    String search = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredOptions = (field.options ?? [])
                .where(
                  (opt) => opt.toLowerCase().contains(search.toLowerCase()),
                )
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Select ${field.label}",
                    style: theme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    onChanged: (val) => setModalState(() => search = val),
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredOptions.length,
                      itemBuilder: (context, idx) {
                        final item = filteredOptions[idx];
                        return ListTile(
                          title: Text(item),
                          trailing: _formValues[field.id] == item
                              ? Icon(
                                  Icons.check_circle,
                                  color: customColor.redColor,
                                )
                              : null,
                          onTap: () {
                            setState(() => _formValues[field.id] = item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
