import 'dart:developer';
import 'package:bloc/bloc.dart';

class SimpleBlocObserver extends BlocObserver {

  // @override
  void OnCreate(BlocBase bloc) {
    super.onCreate(bloc);
    log('OnCreate -- bloc: ${bloc.runtimeType}');
  } 

  // @override
  void OnEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    log('OnEvent -- bloc: ${bloc.runtimeType}, event: $event');
  }

  // @override
  void OnChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log('OnChange -- bloc: ${bloc.runtimeType}, change: $change');
  }

  // @override
  void OnTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    log('OnTransition -- bloc: ${bloc.runtimeType}, transition: $transition');
  }

  // @override
  void OnError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log('OnError -- bloc: ${bloc.runtimeType}, error: $error');
    super.onError(bloc, error, stackTrace);
  }

  // @override
  void OnClose(BlocBase bloc) {
    super.onClose(bloc);
    log('OnClose -- bloc: ${bloc.runtimeType}');
  }
}