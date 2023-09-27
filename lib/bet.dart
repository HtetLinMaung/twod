class Bet {
  final int id;
  final String lottery;
  final double amount;
  final String dateTime;
  final bool r;

  Bet(
      {required this.id,
      required this.lottery,
      required this.amount,
      required this.dateTime,
      required this.r});
}

class SummaryBet {
  final String lottery;
  final double totalAmount;
  final int lotteryCount;
  final bool r;

  SummaryBet({
    required this.lottery,
    required this.totalAmount,
    required this.lotteryCount,
    required this.r,
  });
}

class TotalBet {
  final double totalAmount;
  final int lotteryCount;

  TotalBet({
    required this.totalAmount,
    required this.lotteryCount,
  });
}
