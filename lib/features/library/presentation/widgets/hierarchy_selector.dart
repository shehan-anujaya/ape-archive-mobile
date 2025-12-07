import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/models/tag_model.dart';
import '../../data/providers/library_provider.dart';

class HierarchySelector extends ConsumerStatefulWidget {
  final List<String> selectedTagIds;
  final Function(List<String> tagIds, Map<String, String> tagFilters) onTagsSelected;

  const HierarchySelector({
    super.key,
    required this.selectedTagIds,
    required this.onTagsSelected,
  });

  @override
  ConsumerState<HierarchySelector> createState() => _HierarchySelectorState();
}

class _HierarchySelectorState extends ConsumerState<HierarchySelector> {
  final Map<TagType, TagModel?> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    final hierarchyAsync = ref.watch(hierarchyProvider);

    return hierarchyAsync.when(
      data: (hierarchy) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Breadcrumb navigation
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildBreadcrumb(
                    context,
                    'All',
                    null,
                    () => _clearSelection(),
                    isFirst: true,
                  ),
                  if (_selectedTags[TagType.grade] != null) ...[
                    _buildBreadcrumbDivider(),
                    _buildBreadcrumb(
                      context,
                      _selectedTags[TagType.grade]!.name,
                      Icons.school,
                      () => _clearFrom(TagType.grade),
                    ),
                  ],
                  if (_selectedTags[TagType.subject] != null) ...[
                    _buildBreadcrumbDivider(),
                    _buildBreadcrumb(
                      context,
                      _selectedTags[TagType.subject]!.name,
                      Icons.menu_book,
                      () => _clearFrom(TagType.subject),
                    ),
                  ],
                  if (_selectedTags[TagType.medium] != null) ...[
                    _buildBreadcrumbDivider(),
                    _buildBreadcrumb(
                      context,
                      _selectedTags[TagType.medium]!.name,
                      Icons.language,
                      () => _clearFrom(TagType.medium),
                    ),
                  ],
                  if (_selectedTags[TagType.resourceType] != null) ...[
                    _buildBreadcrumbDivider(),
                    _buildBreadcrumb(
                      context,
                      _selectedTags[TagType.resourceType]!.name,
                      Icons.description,
                      null,
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),
            // Category chips for next level selection
            if (_shouldShowCategoryChips(hierarchy))
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getNextLevelLabel(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getNextLevelOptions(hierarchy)
                          .map((node) => _buildCategoryChip(context, node))
                          .toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load categories',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.refresh(hierarchyProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(
    BuildContext context,
    String label,
    IconData? icon,
    VoidCallback? onTap,
    {
    bool isFirst = false,
    bool isLast = false,
    }
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isLast
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isLast
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isLast
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, TagHierarchyNode node) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectTag(node.tag),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getIconForTagType(node.tag.type),
              const SizedBox(width: 8),
              Text(
                node.tag.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getIconForTagType(TagType type) {
    IconData iconData;
    Color color;
    
    switch (type) {
      case TagType.grade:
        iconData = Icons.school;
        color = Colors.blue;
        break;
      case TagType.subject:
        iconData = Icons.menu_book;
        color = Colors.green;
        break;
      case TagType.medium:
        iconData = Icons.language;
        color = Colors.orange;
        break;
      case TagType.resourceType:
        iconData = Icons.description;
        color = Colors.purple;
        break;
      case TagType.lesson:
        iconData = Icons.book;
        color = Colors.teal;
        break;
    }
    
    return Icon(iconData, size: 18, color: color);
  }

  bool _shouldShowCategoryChips(List<TagHierarchyNode> hierarchy) {
    // Show chips if we haven't reached the leaf level (resourceType)
    return _selectedTags[TagType.resourceType] == null;
  }

  String _getNextLevelLabel() {
    if (_selectedTags[TagType.grade] == null) return 'SELECT GRADE';
    if (_selectedTags[TagType.subject] == null) return 'SELECT SUBJECT';
    if (_selectedTags[TagType.medium] == null) return 'SELECT MEDIUM';
    if (_selectedTags[TagType.resourceType] == null) return 'SELECT RESOURCE TYPE';
    return '';
  }

  List<TagHierarchyNode> _getNextLevelOptions(List<TagHierarchyNode> hierarchy) {
    if (_selectedTags[TagType.grade] == null) {
      return hierarchy;
    }
    if (_selectedTags[TagType.subject] == null) {
      return _getChildren(hierarchy, _selectedTags[TagType.grade]!.id);
    }
    if (_selectedTags[TagType.medium] == null) {
      return _getChildren(hierarchy, _selectedTags[TagType.subject]!.id);
    }
    if (_selectedTags[TagType.resourceType] == null) {
      return _getChildren(hierarchy, _selectedTags[TagType.medium]!.id);
    }
    return [];
  }

  List<TagHierarchyNode> _getChildren(
    List<TagHierarchyNode> hierarchy,
    String parentId,
  ) {
    for (final node in hierarchy) {
      if (node.tag.id == parentId) {
        return node.children;
      }
      final result = _getChildren(node.children, parentId);
      if (result.isNotEmpty) return result;
    }
    return [];
  }

  void _selectTag(TagModel tag) {
    setState(() {
      _selectedTags[tag.type] = tag;
      // Clear child selections
      switch (tag.type) {
        case TagType.grade:
          _selectedTags.remove(TagType.subject);
          _selectedTags.remove(TagType.medium);
          _selectedTags.remove(TagType.resourceType);
          break;
        case TagType.subject:
          _selectedTags.remove(TagType.medium);
          _selectedTags.remove(TagType.resourceType);
          break;
        case TagType.medium:
          _selectedTags.remove(TagType.resourceType);
          break;
        default:
          break;
      }
    });
    _updateSelection();
  }

  void _clearFrom(TagType type) {
    setState(() {
      switch (type) {
        case TagType.grade:
          _selectedTags.clear();
          break;
        case TagType.subject:
          _selectedTags.remove(TagType.subject);
          _selectedTags.remove(TagType.medium);
          _selectedTags.remove(TagType.resourceType);
          break;
        case TagType.medium:
          _selectedTags.remove(TagType.medium);
          _selectedTags.remove(TagType.resourceType);
          break;
        case TagType.resourceType:
          _selectedTags.remove(TagType.resourceType);
          break;
        default:
          break;
      }
    });
    _updateSelection();
  }

  void _clearSelection() {
    setState(() {
      _selectedTags.clear();
    });
    _updateSelection();
  }

  void _updateSelection() {
    final tagIds = _selectedTags.values
        .where((tag) => tag != null)
        .map((tag) => tag!.id)
        .toList();
    
    // Build filter map for API
    final tagFilters = <String, String>{};
    if (_selectedTags[TagType.grade] != null) {
      tagFilters['grade'] = _selectedTags[TagType.grade]!.name;
    }
    if (_selectedTags[TagType.subject] != null) {
      tagFilters['subject'] = _selectedTags[TagType.subject]!.name;
    }
    if (_selectedTags[TagType.medium] != null) {
      tagFilters['medium'] = _selectedTags[TagType.medium]!.name;
    }
    if (_selectedTags[TagType.resourceType] != null) {
      tagFilters['resourceType'] = _selectedTags[TagType.resourceType]!.name;
    }
    
    widget.onTagsSelected(tagIds, tagFilters);
  }
}
