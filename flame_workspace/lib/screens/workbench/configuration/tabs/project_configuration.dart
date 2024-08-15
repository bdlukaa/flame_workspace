part of '../configuration_view.dart';

class _ProjectConfiguration extends StatelessWidget {
  const _ProjectConfiguration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbench = Workbench.of(context);
    final project = workbench.project;

    final projectConfiguration =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Project Configuration', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8.0),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Project Name', style: theme.textTheme.labelMedium),
          Text(project.name),
          const SizedBox(height: 8.0),
          Text('Organization', style: theme.textTheme.labelMedium),
          Text(project.organization),
          const SizedBox(height: 8.0),
          Text('Project version', style: theme.textTheme.labelMedium),
          const Text('0.0.0'),
          const SizedBox(height: 8.0),
          Text('Project dependencies', style: theme.textTheme.labelMedium),
          if (project.dependencies.isEmpty)
            const Text('No dependencies')
          else
            ...project.dependencies.map((e) => Text(e.toString())),
          const SizedBox(height: 8.0),
          Text('Languages', style: theme.textTheme.labelMedium),
          const Text('English'),
        ]),
      ),
    ]);

    final files = workbench.state.files;
    final projectStructure =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Project Structure', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8.0),
      Expanded(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: TreeView(
              initiallyExpanded: false,
              nodes: files.map((entity) {
                if (entity is Directory) {
                  return nodeForDirectory(entity);
                } else {
                  return nodeForFile(entity as File);
                }
              }).toList(),
            ),
          ),
        ),
      ),
    ]);

    return Row(children: [
      projectConfiguration,
      const SizedBox(width: 32.0),
      IntrinsicWidth(child: projectStructure),
    ]);
  }
}
