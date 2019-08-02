import 'package:squazzle/data/data.dart';
import 'game_repo.dart';

/// MultiBloc's repository.
class MultiRepo extends GameRepo {
  final ApiProvider apiProvider;
  final MessagingProvider messProvider;

  MultiRepo(this.apiProvider, this.messProvider, LogicProvider logicProvider,
      DbProvider dbProvider, SharedPrefsProvider prefsProvider)
      : super(
            logicProvider: logicProvider,
            dbProvider: dbProvider,
            prefsProvider: prefsProvider);

  @override
  Future<bool> moveDone(GameField gameField, TargetField targetField) async {
    var need = logicProvider.needToSendMove(gameField, targetField);
    if (need) {
      await prefsProvider.storeGf(gameField);
      await prefsProvider
          .storeTarget(logicProvider.diffToSend(gameField, targetField));
      Session session = await prefsProvider.getCurrentSession();
      bool isCorrect =
          await logicProvider.checkIfCorrect(gameField, targetField);
      print(session.toMap());
      await apiProvider.sendMove(session, isCorrect);
    }
    return logicProvider.checkIfCorrect(gameField, targetField);
  }

  Future<String> getStoredUid() => prefsProvider.getUid();

  Future<GameOnline> queuePlayer() async {
    await prefsProvider.restoreMoves();
    String uid = await prefsProvider.getUid();
    String token = await messProvider.getToken();
    GameOnline situation = await apiProvider.queuePlayer(uid, token);
    prefsProvider.storeMoves(situation.moves);
    prefsProvider.storeMatchId(situation.matchId);
    return situation;
  }

  Future<void> updateUserInfo() => prefsProvider
      .getUid()
      .then((uid) => apiProvider.getUser(uid))
      .then((user) => prefsProvider.storeUser(user));

  void storeMatchId(String matchId) => prefsProvider.storeMatchId(matchId);

  Stream<ChallengeMessage> get challengeMessages =>
      messProvider.challengeMessages;

  Stream<MoveMessage> get moveMessages => messProvider.moveMessages;

  Stream<WinnerMessage> get winnerMessages => messProvider.winnerMessages;
}
