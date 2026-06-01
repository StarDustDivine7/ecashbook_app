import 'package:flutter/material.dart';

class LazyLoader<T> extends StatelessWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext, T) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const LazyLoader({
    Key? key,
    required this.loader,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: loader(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return errorWidget ?? Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}

class LazyComponent<T> extends StatelessWidget {
  final Future<T> Function() loader;
  final Widget Function(T) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const LazyComponent({
    Key? key,
    required this.loader,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: loader(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return errorWidget ?? Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (snapshot.hasData) {
          return builder(snapshot.data!);
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}
