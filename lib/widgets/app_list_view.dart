import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_empty_state.dart';

class AppListView extends StatelessWidget {
  final bool loading;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final Future<void> Function()? onRefresh;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final Widget? header;

  const AppListView({
    super.key,
    required this.loading,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptySubtitle,
    this.onRefresh,
    this.children = const [],
    this.padding,
    this.controller,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = ListView(
      controller: controller,
      padding: padding ?? const EdgeInsets.all(12),
      children: <Widget>[
        if (header != null) header!,
        if (isEmpty)
          AppEmptyState(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle)
        else
          ...children,
      ],
    );

    if (onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: list);
    }

    return list;
  }
}
