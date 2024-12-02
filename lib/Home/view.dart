import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double totalBalance = 0.0;
  double todayTotal = 0.0;
  double thisWeekTotal = 0.0;
  double thisMonthTotal = 0.0;

  Map<String, double> analysis = {
    "Bills": 0.0,
    "Car and transportation": 0.0,
    "Food and Groceries": 0.0,
    "Personal Items": 0.0,
    "Entertainment": 0.0,
    "Maintenance":0.0,
    "Others": 0.0,
  };

  List<Map<String, dynamic>> transactions = [];

  bool isIncome = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', width: 100),
        centerTitle: true,
        backgroundColor: const Color(0xff00796a),
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu),
          color: Colors.white,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "\$${totalBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text('Total Balance',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            color: Colors.white,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildAnalysisSection(),
            const SizedBox(height: 20),
            _buildPeriodSummary(),
            const SizedBox(height: 20),
            _buildDetailsSection(),
            const SizedBox(height: 35),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Add Transaction Dialog
  void _showAddTransactionDialog(BuildContext context) {
    final amountController = TextEditingController();
    String selectedCategory = isIncome ? 'Income' : analysis.keys.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Transaction"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: "Amount"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // Only show category dropdown if it's an expense
                  if (!isIncome)
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: analysis.keys.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Income"),
                      Switch(
                        value: isIncome,
                        onChanged: (value) {
                          setState(() {
                            isIncome = value;
                            // Reset category when income is selected
                            selectedCategory = isIncome ? 'Income' : analysis.keys.first;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (amountController.text.isNotEmpty) {
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      if (amount > 0) {
                        final category = isIncome ? 'Income' : selectedCategory;
                        _addTransaction(category, amount);
                        Navigator.of(ctx).pop();
                      }
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _addTransaction(String category, double amount) {
    setState(() {
      final transactionAmount = isIncome ? amount : -amount;

      // Check for insufficient balance
      if (!isIncome && totalBalance + transactionAmount < 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No Enough balance')));
        return;
      }

      totalBalance += transactionAmount;

      // If it's an expense, update the analysis category
      if (!isIncome) {
        analysis[category] = (analysis[category] ?? 0.0) + transactionAmount;
      }

      transactions.add({
        "date": DateTime.now().toString(),
        "category": category,
        "amount": transactionAmount,
        "type": isIncome ? "Income" : "Expense",
      });

      // Update period summaries
      todayTotal += transactionAmount;
      thisWeekTotal += transactionAmount;
      thisMonthTotal += transactionAmount;
    });
  }

  Widget _buildAnalysisSection() {
    final total = analysis.values.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Analysis",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 150,
                  child: total == 0
                      ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border:
                      Border.all(color: Colors.grey[400]!, width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        "No Data Yet",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                  )
                      : PieChart(
                    PieChartData(
                      sections: analysis.entries
                          .where((entry) => entry.value != 0)
                          .map((entry) {
                        final percentage =
                        (entry.value / total * 100).toDouble();
                        return PieChartSectionData(
                          showTitle: false,
                          value: percentage,
                          title: "${percentage.toStringAsFixed(1)}%",
                          color: _getCategoryColor(entry.key),
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (total > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: analysis.entries
                        .where((entry) => entry.value != 0)
                        .map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            // Small colored box for each category
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(entry.key),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Category name and value
                            Text(
                                "${entry.key} (\$${entry.value.toStringAsFixed(2)})"),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
            Container(
              color: Colors.black54,
              width: 2,
              height: 150,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: Colors.orange,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Bills'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: Colors.purple,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Personal Items'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: Colors.blue,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Car and transportation'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: Colors.red,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Entertainment'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: Colors.green,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Food and Groceries'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: Colors.yellow,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Maintenance'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: Colors.grey,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Other'),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Bills":
        return Colors.orange;
      case "Car and transportation":
        return Colors.blue;
      case "Food and Groceries":
        return Colors.green;
      case "Personal Items":
        return Colors.purple;
      case "Entertainment":
        return Colors.red;
      case "Maintenance":
        return Colors.yellow;
      case "Others":
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Widget _buildPeriodSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPeriodCard("Today", todayTotal),
        _buildPeriodCard("This Week", thisWeekTotal),
        _buildPeriodCard("This Month", thisMonthTotal),
      ],
    );
  }

  Widget _buildPeriodCard(String title, double amount) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "\$${amount.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Details: ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return ListTile(
              leading: Icon(
                transaction['type'] == 'Income'
                    ? Icons.add_circle
                    : Icons.remove_circle,
                color:
                transaction['type'] == 'Income' ? Colors.green : Colors.red,
              ),
              title: Text(transaction['category']),
              subtitle: Text(DateFormat.yMMMd()
                  .format(DateTime.parse(transaction['date']))),
              trailing: Text(
                "\$${transaction['amount'].toStringAsFixed(2)}",
                style: TextStyle(
                  color: transaction['type'] == 'Income'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}