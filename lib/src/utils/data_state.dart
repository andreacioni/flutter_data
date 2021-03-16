library data_state;

import 'package:equatable/equatable.dart';
import 'package:state_notifier/state_notifier.dart';

class DataState<T> with EquatableMixin {
  final T model;
  final bool isLoading;
  final Object exception;
  final StackTrace stackTrace;

  const DataState(
    this.model, {
    this.isLoading = false,
    this.exception,
    this.stackTrace,
  });

  bool get hasException => exception != null;

  bool get hasModel => model != null;

  @override
  List<Object> get props => [model, isLoading, exception, stackTrace];

  @override
  bool get stringify => true;
}

class DataStateNotifier<T> extends StateNotifier<DataState<T>> {
  DataStateNotifier(
    DataState<T> initialData, {
    Future<void> Function(DataStateNotifier<T>) reload,
  })  : _reloadFn = reload,
        super(initialData ?? DataState<T>(null));

  final Future<void> Function(DataStateNotifier<T>) _reloadFn;
  void Function() onDispose;

  DataState<T> get data => super.state;

  void updateWith(
      {Object model = stamp,
      Object isLoading = stamp,
      Object exception = stamp,
      Object stackTrace = stamp}) {
    super.state = DataState<T>(model == stamp ? state.model : model as T,
        isLoading: isLoading == stamp ? state.isLoading : isLoading as bool,
        exception: exception == stamp ? state.exception : exception,
        stackTrace:
            stackTrace == stamp ? state.stackTrace : stackTrace as StackTrace);
  }

  Future<void> reload() async {
    return _reloadFn?.call(this) ?? ((_) {});
  }

  @override
  RemoveListener addListener(
    Listener<DataState<T>> listener, {
    bool fireImmediately = true,
  }) {
    final dispose =
        super.addListener(listener, fireImmediately: fireImmediately);
    return () {
      dispose();
      onDispose?.call();
    };
  }

  @override
  void dispose() {
    if (mounted) {
      super.dispose();
    }
    onDispose?.call();
  }
}

class _Stamp {
  const _Stamp();
}

const stamp = _Stamp();