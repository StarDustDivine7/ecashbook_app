import 'package:flutter/material.dart';

typedef ShowPersistentSheet = PersistentBottomSheetController Function(
  WidgetBuilder builder,
);

class BottomSheetHost extends InheritedWidget {
  final ShowPersistentSheet show;

  const BottomSheetHost({
    super.key,
    required this.show,
    required super.child,
  });

  static BottomSheetHost? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BottomSheetHost>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
