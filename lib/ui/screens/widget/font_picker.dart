import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontPickerSheet extends StatefulWidget {
  final List<String> fonts;
  final String selectedFont;
  final bool isDark;
  final ValueChanged<String> onSelected;

  const FontPickerSheet({
    required this.fonts,
    required this.selectedFont,
    required this.isDark,
    required this.onSelected,
  });

  @override
  State<FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends State<FontPickerSheet> {
  late final TextEditingController _searchController;
  late String _selectedFont;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedFont = widget.selectedFont;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFonts = widget.fonts
        .where(
          (font) => font
          .toLowerCase()
          .contains(_searchController.text.trim().toLowerCase()),
    )
        .toList();

    final background = widget.isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    final foreground = widget.isDark
        ? Colors.white
        : Colors.black87;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.font_download_rounded,
                    color: foreground,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Choose Font',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${filteredFonts.length} fonts',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: foreground),
                decoration: InputDecoration(
                  hintText: 'Search fonts...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: widget.isDark
                      ? const Color(0xFF303030)
                      : const Color(0xFFF3F3F3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredFonts.isEmpty
                  ? const Center(
                child: Text('No fonts found'),
              )
                  : ListView.builder(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: filteredFonts.length,
                itemBuilder: (context, index) {
                  final font = filteredFonts[index];
                  final isSelected =
                      font.toLowerCase() ==
                          _selectedFont.toLowerCase();

                  return ListTile(
                    onTap: () {
                      setState(() => _selectedFont = font);
                      widget.onSelected(font);
                    },
                    title: Text(
                      font,
                      style: GoogleFonts.getFont(
                        font,
                        color: foreground,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Text(
                      'The quick brown fox',
                      style: GoogleFonts.getFont(
                        font,
                        color: foreground.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.blue,
                    )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}