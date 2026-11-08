import 'package:flutter/material.dart';
import 'controller.dart';
import 'localization.dart';

const _muted = Color(0xFF78767E);

Future<void> pickPreviewColor(
  BuildContext context,
  FontController c,
  bool foreground,
) async {
  final color = await showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ColorPicker(
      initial: foreground ? c.ink : c.paper,
      foreground: foreground,
    ),
  );
  if (color != null) {
    foreground ? c.setInk(color) : c.setPaper(color);
  }
}

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.initial, required this.foreground});
  final Color initial;
  final bool foreground;
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late Color color = widget.initial;
  late final hex = TextEditingController(text: _hex(color));
  bool invalid = false;
  static String _hex(Color c) =>
      c.toARGB32().toRadixString(16).substring(2).toUpperCase();
  void change(Color next) {
    setState(() {
      color = next;
      hex.text = _hex(next);
      invalid = false;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.foreground
                  ? context.l10n.textColor
                  : context.l10n.backgroundColor,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  const [
                        0xFF252329,
                        0xFFFFFFFF,
                        0xFFFFFBF5,
                        0xFFD9437B,
                        0xFFCC4149,
                        0xFF28745B,
                        0xFF896344,
                        0xFF7655AB,
                        0xFF467EB5,
                      ]
                      .map(
                        (argb) => Semantics(
                          label: '#${argb.toRadixString(16).substring(2)}',
                          button: true,
                          child: InkWell(
                            onTap: () => change(Color(argb)),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(argb),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _muted.withValues(alpha: .3),
                                ),
                              ),
                              child: color.toARGB32() == argb
                                  ? Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Color(argb).computeLuminance() > .5
                                          ? Colors.black
                                          : Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            for (final channel in ['R', 'G', 'B'])
              Row(
                children: [
                  SizedBox(width: 20, child: Text(channel)),
                  Expanded(
                    child: Slider(
                      value: switch (channel) {
                        'R' => color.r * 255,
                        'G' => color.g * 255,
                        _ => color.b * 255,
                      },
                      min: 0,
                      max: 255,
                      divisions: 255,
                      label: switch (channel) {
                        'R' => '${(color.r * 255).round()}',
                        'G' => '${(color.g * 255).round()}',
                        _ => '${(color.b * 255).round()}',
                      },
                      onChanged: (value) => change(
                        Color.fromARGB(
                          255,
                          channel == 'R'
                              ? value.round()
                              : (color.r * 255).round(),
                          channel == 'G'
                              ? value.round()
                              : (color.g * 255).round(),
                          channel == 'B'
                              ? value.round()
                              : (color.b * 255).round(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: hex,
              maxLength: 6,
              decoration: InputDecoration(
                prefixText: '# ',
                labelText: 'HEX',
                errorText: invalid ? context.l10n.invalidHex : null,
              ),
              onChanged: (value) => setState(() {
                if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) {
                  color = Color(0xFF000000 | int.parse(value, radix: 16));
                  invalid = false;
                } else {
                  invalid = true;
                }
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !invalid
                    ? () => Navigator.pop(context, color)
                    : null,
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(context.l10n.apply),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }
}
