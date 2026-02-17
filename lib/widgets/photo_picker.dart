import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PhotoPicker extends StatelessWidget {
  const PhotoPicker({
    super.key,
    required this.photoUrls,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final List<String> photoUrls;
  final VoidCallback onAddPhoto;
  final void Function(int index) onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...photoUrls.asMap().entries.map(
              (entry) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: entry.value,
                      width: 90,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => onRemovePhoto(entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (photoUrls.length < 6)
              InkWell(
                onTap: onAddPhoto,
                child: Container(
                  width: 90,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.4,
                    ),
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
