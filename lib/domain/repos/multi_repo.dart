import 'package:squazzle/data/data.dart';
import 'game_repo.dart';

/// MultiBloc's repository.
class MultiRepo extends GameRepo {
  final ApiProvider apiProvider;
  final MessagingEventBus messProvider;
  final SharedPrefsProvider prefsProvider;
  String matchId;

  MultiRepo(this.apiProvider, this.messProvider, this.prefsProvider,
      LogicProvider logicProvider, DbProvider dbProvider)
      : super(
          logicProvider: logicProvider,
          dbProvider: dbProvider,
        );

  @override
  Future<int> getMoves() async {
    ActiveMatch activeMatch = await dbProvider.getActiveMatch(matchId);
    return activeMatch.moves;
  }

  @override
  Future<void> increaseMoves() async {
    ActiveMatch activeMatch = await dbProvider.getActiveMatch(matchId);
    activeMatch.moves += 1;
    await dbProvider.updateActiveMatch(activeMatch);
    messProvider.refreshMatchList();
  }

  @override
  Future<bool> moveDone(GameField gameField, TargetField targetField) async {
    ActiveMatch currentMatch = await dbProvider.getActiveMatch(matchId);
    currentMatch.gameField = gameField;
    dbProvider.updateActiveMatch(currentMatch);
    if (logicProvider.needToSendMove(gameField, targetField)) {
      TargetField newTarget = logicProvider.diffToSend(gameField, targetField);
      String uid = await prefsProvider.getUid();
      bool isCorrect =
          await logicProvider.checkIfCorrect(gameField, targetField);
      await apiProvider.sendMove(currentMatch, newTarget.grid, uid, isCorrect);
    }
    return logicProvider.checkIfCorrect(gameField, targetField);
  }

  Future<bool> forfeit() async {
    var userId = await prefsProvider.getUid();
    await dbProvider.deleteActiveMatch(matchId);
    return apiProvider.sendForfeit(userId, matchId);
  }

  Future<ActiveMatch> queuePlayer() async {
    String uid = await prefsProvider.getUid();
    String token = await messProvider.getToken();
    ActiveMatch currentMatch = await apiProvider.queuePlayer(uid, token);
    matchId = currentMatch.matchId;
    return currentMatch;
  }

  Future<ActiveMatch> connectPlayer(String connectMatchId) async {
    String uid = await prefsProvider.getUid();
    String token = await messProvider.getToken();
    ActiveMatch connectedMatch =
        await apiProvider.reconnect(uid, token, connectMatchId);
    dbProvider.storeActiveMatch(connectedMatch);
    matchId = connectedMatch.matchId;
    return connectedMatch;
  }
}
