import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twod/bet.dart';
import 'package:twod/database_helper.dart';
import 'package:intl/intl.dart';
// import 'package:twod/utils.dart';
import 'package:google_fonts/google_fonts.dart';

enum ViewType { listView, summaryView }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2D App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
        // cardColor: Colors.white,
      ),
      home: const MyHomePage(title: '2D App Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ViewType selectedViewType = ViewType.listView;
  TextEditingController lotteryController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  bool isReverseValid = false;
  List<Bet> bets = [];
  List<SummaryBet> summaryBets = [];
  DateTime? fromDate;
  DateTime? toDate;
  String search = "";
  double totalAmount = 0.0;
  int lotteryCount = 0;
  final formatter = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    initializeFilterDates();
    _fetchBets();
  }

  _fetchBets() async {
    final dbHelper = DatabaseHelper.instance;
    bets = await dbHelper.queryRows(fromDate!, toDate!, search);
    var totalBet = await dbHelper.getTotalForList(fromDate!, toDate!, search);
    totalAmount = totalBet.totalAmount;
    lotteryCount = totalBet.lotteryCount;
    setState(() {});
  }

  _fetchSummaryBets() async {
    final dbHelper = DatabaseHelper.instance;
    summaryBets = await dbHelper.getSummary(fromDate!, toDate!, search);
    var totalBet =
        await dbHelper.getTotalForSummary(fromDate!, toDate!, search);
    totalAmount = totalBet.totalAmount;
    lotteryCount = totalBet.lotteryCount;
    setState(() {});
  }

  void initializeFilterDates() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime noon = startOfDay.add(const Duration(hours: 12));
    DateTime endOfDay = startOfDay.add(const Duration(days: 1, seconds: -1));

    if (now.isBefore(noon)) {
      fromDate = startOfDay;
      toDate = noon;
    } else {
      fromDate = noon.add(const Duration(minutes: 1));
      toDate = endOfDay;
    }
  }

  void showFilterDialog(DateTime? fromDate, DateTime? toDate, String? search) {
    final TextEditingController searchController =
        TextEditingController(text: search);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              surfaceTintColor: Colors.white,
              title: Text(
                'ရှာဖွေစစ်ထုတ်မှု',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 22,
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: GoogleFonts.poppins(),
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'ရှာရန် (စာသားဖြင့်)',
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: fromDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null && selectedDate != fromDate) {
                        // ignore: use_build_context_synchronously
                        final TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              fromDate ?? DateTime.now()),
                        );
                        if (selectedTime != null) {
                          fromDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          setState(() {});
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'စတင်သည့်ရက်စွဲ',
                      ),
                      child: Text(
                        fromDate != null
                            ? DateFormat('dd/MM/yyyy hh:mm a').format(fromDate!)
                            : 'ရက်စွဲနှင့် အချိန်ကို ရွေးပါ',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: toDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null && selectedDate != toDate) {
                        // ignore: use_build_context_synchronously
                        final TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(toDate ?? DateTime.now()),
                        );
                        if (selectedTime != null) {
                          toDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          setState(() {});
                        }
                      }
                    },
                    child: InputDecorator(
                      baseStyle: GoogleFonts.poppins(),
                      decoration: const InputDecoration(
                        labelText: 'ကုန်ဆုံးသည့်ရက်စွဲ',
                      ),
                      child: Text(
                        toDate != null
                            ? DateFormat('dd/MM/yyyy hh:mm a').format(toDate!)
                            : 'ရက်စွဲနှင့် အချိန်ကို ရွေးပါ',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    'ပယ်ဖျက်ပါ',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Apply the filters and refresh the list of bets
                    applyFilters(fromDate, toDate, searchController.text);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    'ရှာမယ်',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void applyFilters(DateTime? fromDate, DateTime? toDate, String searchText) {
    this.fromDate = fromDate;
    this.toDate = toDate;
    search = searchText;
    if (selectedViewType == ViewType.listView) {
      _fetchBets();
    } else {
      _fetchSummaryBets();
    }
  }

  void showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: Text(
            'ဖျက်ရန်အတည်ပြုပါ',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                fontSize: 22,
              ),
            ),
          ),
          content: Text(
            'ဖျက်လိုသည်မှာ သေချာပါသလား?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'ပယ်ဖျက်ပါ',
                style: GoogleFonts.poppins(),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Delete the bet from the database
                final dbHelper = DatabaseHelper.instance;
                await dbHelper.delete(id);
                // Refresh the list of bets
                // setState(() {
                //   bets.removeWhere((bet) => bet.id == id);
                // });
                await _fetchBets();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'ဖျက်မယ်',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  void showBettingDialog([Bet? bet]) {
    // Initialize controllers and checkbox with existing values if in edit mode
    lotteryController.text = bet?.lottery ?? '';
    amountController.text = bet != null ? bet.amount.toString() : '';
    isReverseValid = bet?.r ?? false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              surfaceTintColor: Colors.white,
              title: Text(
                bet != null ? '၂ လုံးထီ မွမ်းမံမယ်' : '၂ လုံးထီ သိမ်းမယ်',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 22,
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: GoogleFonts.poppins(),
                    controller: lotteryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '၂ လုံးထီ',
                    ),
                    maxLength: 2, // Set maximum length
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter
                          .digitsOnly // Ensure only digits are allowed
                    ],
                  ),
                  TextField(
                    style: GoogleFonts.poppins(),
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ပမာဏ',
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isReverseValid,
                        onChanged: (bool? value) {
                          setState(() {
                            isReverseValid = value ?? false;
                          });
                        },
                      ),
                      Text(
                        'အာ',
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear the TextFields and Checkbox
                    lotteryController.clear();
                    amountController.clear();
                    setState(() {
                      isReverseValid = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'ပယ်ဖျက်ပါ',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (lotteryController.text.isEmpty ||
                        amountController.text.isEmpty) {
                      return;
                    }
                    var lottery = lotteryController.text;
                    var amount = double.parse(amountController.text);
                    var dateTime = DateTime.now().toIso8601String();
                    var rValue = isReverseValid ? 1 : 0;
                    var row = {
                      DatabaseHelper.columnLottery: lottery,
                      DatabaseHelper.columnAmount: amount,
                      DatabaseHelper.columnR:
                          lottery[0] == lottery[1] ? false : rValue,
                    };

                    final dbHelper = DatabaseHelper.instance;
                    if (bet != null) {
                      // Update the existing row
                      await dbHelper.update(bet.id, row);
                    } else {
                      row[DatabaseHelper.columnDateTime] = dateTime;

                      await dbHelper.insert(row);
                    }
                    if (selectedViewType == ViewType.listView) {
                      await _fetchBets();
                    } else {
                      await _fetchSummaryBets();
                    }

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    bet != null ? 'မွမ်းမံမယ်' : 'သိမ်းမယ်',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEFF0F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '၂ လုံးထီ စာရင်း',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: Colors.black,
            ),
            onPressed: () {
              showFilterDialog(fromDate, toDate, search);
            },
          ),
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: const PopupMenuThemeData(
                surfaceTintColor:
                    Colors.white, // Set the overlay color to transparent
              ),
              // cardColor: Colors
              //     .red, // Set the background color of PopupMenuEntry to white
            ),
            child: PopupMenuButton<ViewType>(
              color: Colors.white,
              icon: const Icon(
                Icons.view_module,
                color: Colors.black,
                // color: Colors.white,
              ),
              // color: Colors.white, // Set the popup background to white
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              onSelected: (ViewType result) {
                if (result == ViewType.summaryView) {
                  _fetchSummaryBets();
                } else {
                  _fetchBets();
                }
                setState(() {
                  selectedViewType = result;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<ViewType>>[
                PopupMenuItem<ViewType>(
                  value: ViewType.listView,
                  child: ListTile(
                    leading: selectedViewType == ViewType.listView
                        ? const Icon(Icons.check)
                        : const Icon(
                            Icons.check,
                            color: Colors.transparent,
                          ),
                    title: Text(
                      'စာရင်း',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ), // Make the text a little smaller
                    ),
                  ),
                ),
                PopupMenuItem<ViewType>(
                  value: ViewType.summaryView,
                  child: ListTile(
                    leading: selectedViewType == ViewType.summaryView
                        ? const Icon(Icons.check)
                        : const Icon(
                            Icons.check,
                            color: Colors.transparent,
                          ),
                    title: Text(
                      'အကျဉ်းချုပ်',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ), // Make the text a little smaller
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: search.isEmpty &&
              ((selectedViewType == ViewType.listView && bets.isEmpty) ||
                  (selectedViewType == ViewType.summaryView &&
                      summaryBets.isEmpty))
          ? Center(
              child: Text(
                'အသစ်ထည့်ရန် အပေါင်းခလုတ်ကို တို့ပါ။',
                style: GoogleFonts.poppins(),
              ),
            )
          : selectedViewType == ViewType.listView
              ? Column(
                  children: [
                    // Display the total amount above the ListView
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ပမာဏ: ${formatter.format(totalAmount)}',
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'အရေအတွက်: $lotteryCount',
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Use Expanded widget to allow the ListView to take the remaining space
                    Expanded(
                      child: ListView.builder(
                        itemCount: bets.length,
                        itemBuilder: (context, index) {
                          final bet = bets[index];
                          // Format the date
                          final dateFormat =
                              DateFormat('dd/MM/yyyy hh:mm:ss a');
                          final formattedDate =
                              dateFormat.format(DateTime.parse(bet.dateTime));

                          // Display lottery digit with or without 'r'
                          var displayText =
                              bet.r ? '${bet.lottery}R' : bet.lottery;
                          displayText += " - ${formatter.format(bet.amount)}";

                          return Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 10.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayText,
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20.0),
                                      onPressed: () {
                                        showBettingDialog(bet);
                                      },
                                    ),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.delete, size: 20.0),
                                      onPressed: () {
                                        showDeleteConfirmationDialog(bet.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ပမာဏ: ${formatter.format(totalAmount)}',
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'အရေအတွက်: $lotteryCount',
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: summaryBets.length,
                        itemBuilder: (context, index) {
                          var summary = summaryBets[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            // elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      summary.lottery + (summary.r ? "R" : ""),
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                        height:
                                            8.0), // Add some spacing between the title and subtitle
                                    Text(
                                      'စုစုပေါင်းပမာဏ - ${formatter.format(summary.totalAmount)}',
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'အရေအတွက် - ${summary.lotteryCount}',
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: showBettingDialog,
        tooltip: 'အပေါင်းခလုတ်',
        backgroundColor: Colors.white, // Set background color to white
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
