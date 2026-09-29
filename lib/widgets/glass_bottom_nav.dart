import 'package:flutter/material.dart';
import '../theme.dart';
import 'glass_panel.dart';

/// Floating frosted-glass bottom navigation bar, replacing the old top
/// tabs. The three destinations match the previous tabs: Library,
/// Playlists, Favorites.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.library_music_outlined, Icons.library_music, 'Library'),
    (Icons.queue_music_outlined, Icons.queue_music, 'Playlists'),
    (Icons.favorite_border, Icons.favorite, 'Favorites'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final selected = i == index;
              final (outline, filled, label) = _items[i];
              final onSurface = Theme.of(context).colorScheme.onSurfaceVariant;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? filled : outline,
                        color: selected ? AppColors.accent : onSurface,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected ? AppColors.accent : onSurface,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
