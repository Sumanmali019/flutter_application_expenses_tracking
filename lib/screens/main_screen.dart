import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cash_compass/components/transaction/render_income_expense.dart';
import 'package:cash_compass/helpers/constants.dart';
import 'package:cash_compass/helpers/db.dart';
import 'package:cash_compass/helpers/transaction_helpers.dart';
import 'package:cash_compass/screens/crud_transaction.dart';
import 'package:fl_chart/fl_chart.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  void fetchTransactions() async {
    var dbHelper = DatabaseHelper();
    transactions = await dbHelper.getTransactions();
    setState(() {});
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(barsSpace: 4, x: x, barRods: [
      BarChartRodData(
        toY: y1,
        color: Colors.redAccent,
        width: 16,
      ),
      BarChartRodData(
        toY: y2,
        color: Colors.greenAccent,
        width: 16,
      ),
    ]);
  }

  Widget buildPieChart() {
    double totalIncome = 0;
    double totalExpense = 0;

    transactions.forEach((transaction) {
      if (transaction.type == incomeConstant) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    });

    // Calculate the total for computing percentages
    double total = totalIncome + totalExpense;

    // Avoid division by zero
    if (total == 0) return Container(child: Text("No Data"));

    return PieChart(PieChartData(
      sections: [
        PieChartSectionData(
          color: Colors.greenAccent,
          value: (totalIncome / total) * 100,
          title: 'Credit\n${((totalIncome / total) * 100).toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        PieChartSectionData(
          color: Colors.redAccent,
          value: (totalExpense / total) * 100,
          title: 'Debit\n${((totalExpense / total) * 100).toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
      sectionsSpace: 2,
      centerSpaceRadius: 40,
    ));
  }

  Widget buildChart() {
    List<BarChartGroupData> barGroups = [];
    double totalIncome = 0;
    double totalExpense = 0;

    transactions.forEach((transaction) {
      if (transaction.type == incomeConstant) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    });

    barGroups.add(makeGroupData(0, totalExpense, totalIncome));

    return BarChart(BarChartData(
      barGroups: barGroups,
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(show: false),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final months = getMonths();

    return DefaultTabController(
      length: months.length,
      initialIndex: months.length - 1,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/icon.png',
                height: 25.0,
                width: 25.0,
              ),
              const SizedBox(width: 8.0),
              const Text('Track Expenses',
                  style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
            ],
          ),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            tabs: months.map((month) {
              String monthYear = DateFormat('MMMM yyyy').format(month);
              return Tab(text: monthYear.toUpperCase());
            }).toList(),
            labelColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: months.map((month) {
            List<Transaction> monthTransactions =
                transactions.where((transaction) {
              DateTime transactionDate = DateTime.parse(transaction.date);
              return transactionDate.month == month.month &&
                  transactionDate.year == month.year;
            }).toList();

            if (monthTransactions.isEmpty) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'No transactions for this month',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Start adding transactions by clicking the +',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  )
                ],
              );
            }

            Map<String, List<Transaction>> groupedTransactions =
                groupTransactionsByDate(monthTransactions);

            return Column(
              children: [
                Expanded(flex: 2, child: buildPieChart()), // Chart display
                Expanded(
                  flex: 5,
                  child: ListView.builder(
                    itemCount: groupedTransactions.length + 1,
                    padding: const EdgeInsets.only(top: 12),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return RenderIncomeExpense(
                            transactions: monthTransactions);
                      }
                      String date =
                          groupedTransactions.keys.elementAt(index - 1);
                      List<Transaction> transactionsForDate =
                          groupedTransactions[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: 1.0, // 100% of the width
                            child: Container(
                              margin: const EdgeInsets.only(
                                top: 12,
                                bottom: 4,
                              ),
                              color: Colors.green[50],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                child: Text(
                                  DateFormat('d MMMM yyyy')
                                      .format(DateTime.parse(date)),
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ...transactionsForDate.map((transaction) {
                            Color color = transaction.type == incomeConstant
                                ? Colors.green
                                : Colors.red;
                            String currencySymbol = currencies.firstWhere(
                              (element) =>
                                  element['currency'] == transaction.currency,
                              orElse: () => {'symbol': transaction.currency},
                            )['symbol'];
                            IconData icon = (transactionTypes.firstWhere(
                              (element) => element['name'] == transaction.type,
                            )['categories'] as List)
                                .firstWhere(
                              (element) =>
                                  element['name'] == transaction.category,
                              orElse: () => {'icon': Icons.category},
                            )['icon'];

                            return ListTile(
                              leading: Icon(icon, color: color, size: 36.0),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.category,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16.0),
                                  ),
                                  if (transaction.note != '')
                                    Container(
                                      margin: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        transaction.note,
                                        style: const TextStyle(fontSize: 14.0),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                '$currencySymbol ${transaction.amount}',
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0),
                              ),
                              onTap: () {
                                print('------------------->>');
                                debugPrint(
                                    'Transaction ${transaction.id} tapped');
                                Navigator.of(context)
                                    .push(
                                  MaterialPageRoute(
                                    builder: (context) => CrudTransaction(
                                      transaction: transaction,
                                    ),
                                  ),
                                )
                                    .then((_) {
                                  fetchTransactions();
                                });
                              },
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => const CrudTransaction(),
              ),
            )
                .then((_) {
              fetchTransactions();
            });
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
