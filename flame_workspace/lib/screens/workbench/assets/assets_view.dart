import 'dart:io';

import 'package:flutter/material.dart';

import '../../../workbench/assets/asset_discovery.dart';
import '../workbench_view.dart';

class AssetsView extends StatefulWidget {
  const AssetsView({super.key});

  @override
  State<AssetsView> createState() => _AssetsViewState();
}

class _AssetsViewState extends State<AssetsView> {
  String? _selectedAssetPath;

  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);
    final state = workbench.state;
    final selectedComponent = state.selectedComponent;
    final selectedComponentId = selectedComponent?.id;
    final selectedAsset = _findSelectedAsset(state.assets);
    final canAssign =
        selectedComponentId != null &&
        _isSpriteLike(
          selectedComponent!.type.name,
          selectedComponent.type.baseType,
        );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Game Assets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Images declared by flutter.assets in pubspec.yaml.'),
          if (state.missingAssetPaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Missing assets: ${state.missingAssetPaths.join(', ')}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (state.assetDiagnostics.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              state.assetDiagnostics.join('\n'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: state.assets.isEmpty
                ? const Center(child: Text('No supported image assets found.'))
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          mainAxisExtent: 156,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: state.assets.length,
                    itemBuilder: (context, index) {
                      final asset = state.assets[index];
                      return _AssetTile(
                        asset: asset,
                        selected: asset.path == _selectedAssetPath,
                        onTap: () =>
                            setState(() => _selectedAssetPath = asset.path),
                      );
                    },
                  ),
          ),
          if (selectedAsset != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Selected: ${selectedAsset.path}')),
                FilledButton.icon(
                  onPressed: canAssign
                      ? () {
                          state.updateComponentAsset(
                            selectedComponentId,
                            selectedAsset.path,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.image),
                  label: const Text('Use for selected sprite'),
                ),
              ],
            ),
            if (!canAssign)
              const Text(
                'Select a SpriteComponent or sprite subclass to assign an image.',
              ),
          ],
        ],
      ),
    );
  }

  WorkspaceAsset? _findSelectedAsset(List<WorkspaceAsset> assets) {
    for (final asset in assets) {
      if (asset.path == _selectedAssetPath) return asset;
    }
    return null;
  }
}

class const _AssetTile({
  required final WorkspaceAsset asset,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: asset.path,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: selected ? color.primary : Colors.transparent,
              width: selected ? 2 : 0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.file(
                  File(asset.absolutePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  asset.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isSpriteLike(String typeName, String? baseType) {
  return typeName.contains('Sprite') || baseType?.contains('Sprite') == true;
}
