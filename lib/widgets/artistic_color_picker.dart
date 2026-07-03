import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class ArtisticColorPicker extends StatefulWidget {

  const ArtisticColorPicker({
    required this.initialColor, required this.onColorChanged, super.key,
  });
  final Color initialColor;
  final Function(Color) onColorChanged;

  @override
  State<ArtisticColorPicker> createState() => _ArtisticColorPickerState();
}

class _ArtisticColorPickerState extends State<ArtisticColorPicker>
    with SingleTickerProviderStateMixin {
  late Color _selectedColor;
  late TabController _tabController;
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _tabController = TabController(length: 3, vsync: this);

    final hslColor = HSLColor.fromColor(_selectedColor);
    _hue = hslColor.hue;
    _saturation = hslColor.saturation;
    _lightness = hslColor.lightness;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateColor(Color color) {
    setState(() {
      _selectedColor = color;
      final hslColor = HSLColor.fromColor(color);
      _hue = hslColor.hue;
      _saturation = hslColor.saturation;
      _lightness = hslColor.lightness;
    });
    widget.onColorChanged(color);
  }

  void _updateFromHSL() {
    final color =
        HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor();
    _updateColor(color);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.palette), text: 'Palettes'),
                Tab(icon: Icon(Icons.tune), text: 'Custom'),
                Tab(icon: Icon(Icons.grid_on), text: 'Grid'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPalettesTab(),
                  _buildCustomTab(),
                  _buildGridTab(),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(space16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choose Your Color',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.shuffle),
                tooltip: 'Random color',
                onPressed: () {
                  final random = Random();
                  final color = Color.fromARGB(
                    255,
                    random.nextInt(256),
                    random.nextInt(256),
                    random.nextInt(256),
                  );
                  _updateColor(color);
                },
              ),
            ],
          ),
          const SizedBox(height: space16),
          _buildPreview(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _selectedColor,
      brightness: Theme.of(context).brightness,
    );

    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: brSm,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: ClipRRect(
        borderRadius: brSm,
        child: Row(
          children: [
            _buildPreviewColor(scheme.primary, 'Primary'),
            _buildPreviewColor(scheme.secondary, 'Secondary'),
            _buildPreviewColor(scheme.tertiary, 'Tertiary'),
            _buildPreviewColor(scheme.surface, 'Surface'),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewColor(Color color, String label) {
    final luminance = color.computeLuminance();
    final textColor = luminance > 0.5 ? Colors.black : Colors.white;

    return Expanded(
      child: ColoredBox(
        color: color,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPalettesTab() {
    final palettes = {
      'Energetic': [
        Colors.red,
        Colors.orange,
        Colors.amber,
        Colors.deepOrange,
        Colors.pink,
        Colors.yellow,
      ],
      'Calm': [
        Colors.blue,
        Colors.cyan,
        Colors.teal,
        Colors.lightBlue,
        Colors.blueGrey,
        Colors.indigo,
      ],
      'Natural': [
        Colors.green,
        Colors.lightGreen,
        Colors.lime,
        Colors.brown,
        Colors.teal,
        const Color(0xFF8D6E63),
      ],
      'Elegant': [
        Colors.purple,
        Colors.deepPurple,
        Colors.indigo,
        Colors.blueGrey,
        const Color(0xFF5E35B1),
        const Color(0xFF4A148C),
      ],
      'Bold': [
        Colors.pink,
        Colors.red,
        Colors.purple,
        Colors.deepPurple,
        const Color(0xFFC2185B),
        const Color(0xFF6A1B9A),
      ],
      'Pastel': [
        const Color(0xFFFFCDD2),
        const Color(0xFFF8BBD0),
        const Color(0xFFE1BEE7),
        const Color(0xFFD1C4E9),
        const Color(0xFFC5CAE9),
        const Color(0xFFBBDEFB),
      ],
    };

    return ListView(
      padding: const EdgeInsets.all(space16),
      children: palettes.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map(_buildColorChip).toList(),
            ),
            const SizedBox(height: space16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildColorChip(Color color) {
    final isSelected = _selectedColor.toARGB32() == color.toARGB32();
    // Chip is a literal swatch value (user-pickable), but the selection
    // checkmark is chrome — pick readable ink from the swatch's luminance.
    final checkColor =
        color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return InkWell(
      onTap: () => _updateColor(color),
      borderRadius: brSm,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: brSm,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected ? Icon(Icons.check, color: checkColor) : null,
      ),
    );
  }

  Widget _buildCustomTab() {
    return ListView(
      padding: const EdgeInsets.all(space16),
      children: [
        _buildHueSlider(),
        const SizedBox(height: space24),
        _buildSaturationSlider(),
        const SizedBox(height: space24),
        _buildLightnessSlider(),
        const SizedBox(height: space32),
        _buildColorCodeDisplay(),
      ],
    );
  }

  Widget _buildHueSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hue',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: space8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _hue,
            max: 360,
            onChanged: (value) {
              setState(() {
                _hue = value;
              });
              _updateFromHSL();
            },
          ),
        ),
        _buildHueGradientBar(),
      ],
    );
  }

  Widget _buildHueGradientBar() {
    return Container(
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: brPill,
        gradient: const LinearGradient(
          colors: [
            Colors.red,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Color(0xFFFF00FF), // Magenta
            Colors.red,
          ],
        ),
      ),
    );
  }

  Widget _buildSaturationSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saturation',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: space8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _saturation,
            onChanged: (value) {
              setState(() {
                _saturation = value;
              });
              _updateFromHSL();
            },
          ),
        ),
        _buildSaturationGradientBar(),
      ],
    );
  }

  Widget _buildSaturationGradientBar() {
    final baseColor = HSLColor.fromAHSL(1, _hue, 0, _lightness).toColor();
    final saturatedColor =
        HSLColor.fromAHSL(1, _hue, 1, _lightness).toColor();

    return Container(
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: brPill,
        gradient: LinearGradient(
          colors: [baseColor, saturatedColor],
        ),
      ),
    );
  }

  Widget _buildLightnessSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lightness',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: space8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _lightness,
            onChanged: (value) {
              setState(() {
                _lightness = value;
              });
              _updateFromHSL();
            },
          ),
        ),
        _buildLightnessGradientBar(),
      ],
    );
  }

  Widget _buildLightnessGradientBar() {
    final darkColor = HSLColor.fromAHSL(1, _hue, _saturation, 0).toColor();
    final lightColor = HSLColor.fromAHSL(1, _hue, _saturation, 1).toColor();

    return Container(
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: brPill,
        gradient: LinearGradient(
          colors: [darkColor, lightColor],
        ),
      ),
    );
  }

  Widget _buildColorCodeDisplay() {
    final hex =
        '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    return Container(
      padding: const EdgeInsets.all(space16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: brSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hex Code',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SelectableText(
                hex,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RGB',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${(_selectedColor.r * 255.0).round().clamp(0, 255)}, ${(_selectedColor.g * 255.0).round().clamp(0, 255)}, ${(_selectedColor.b * 255.0).round().clamp(0, 255)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(space16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 360,
      itemBuilder: (context, index) {
        final hue = index.toDouble();
        final colors = [
          HSLColor.fromAHSL(1, hue, 0.7, 0.3).toColor(),
          HSLColor.fromAHSL(1, hue, 0.8, 0.5).toColor(),
          HSLColor.fromAHSL(1, hue, 0.9, 0.6).toColor(),
        ];

        return GestureDetector(
          onTap: () => _updateColor(colors[index % 3]),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedColor.toARGB32() == colors[index % 3].toARGB32()
                    ? Colors.white
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: space8),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(_selectedColor);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
