import 'package:rxdart/rxdart.dart';

import 'package:squazzle/data/models/models.dart';
import 'package:squazzle/domain/domain.dart';

class EnemyFieldBloc extends BlocEventStateBase<GameEvent, GameState> {
  final MultiBloc _multiBloc;

  final _enemyFieldSubject = BehaviorSubject<TargetField>();
  Stream<TargetField> get enemyField => _enemyFieldSubject.stream;

  EnemyFieldBloc(this._multiBloc);

  @override
  Stream<GameState> eventHandler(
      GameEvent event, GameState currentState) async* {
    if (event.type == GameEventType.start) {
      _enemyFieldSubject.add(_multiBloc.enemyField);
    }
  }

  @override
  void dispose() {
    _enemyFieldSubject.close();
    super.dispose();
  }
}
