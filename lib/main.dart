import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainApp()
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    AnalysisPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TA Expense'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecondRoute()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analysis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Item 1'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Item 2'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _chartImage;
  List<dynamic> _todayTransactions = [];
  bool _isLoadingChart = true;
  bool _isLoadingTransactions = true;

  // Fetch the pie chart from the backend
  Future<void> fetchPieChart() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/pie_chart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'transactions': [], // You can pass all transactions or filter them
          'chartType': 'category',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _chartImage = response.bodyBytes;
          _isLoadingChart = false;
        });
      } else {
        throw Exception('Failed to load pie chart');
      }
    } catch (e) {
      setState(() {
        _isLoadingChart = false;
      });
      print('Error fetching pie chart: $e');
    }
  }

  // Fetch today's transactions from the backend
  Future<void> fetchTodayTransactions() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/transactions'));
      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);

        // Filter transactions for today
        final today = DateTime.now();
        final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        final todayTransactions = transactions.where((transaction) {
          return transaction['date'] == todayString;
        }).toList();

        setState(() {
          _todayTransactions = todayTransactions;
          _isLoadingTransactions = false;
        });
      } else {
        throw Exception('Failed to fetch transactions');
      }
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
      });
      print('Error fetching transactions: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPieChart();
    fetchTodayTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top box for the pie chart
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: _isLoadingChart
                    ? const Center(child: CircularProgressIndicator())
                    : _chartImage == null
                        ? const Center(
                            child: Text(
                              'Failed to load pie chart',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          )
                        : Image.memory(
                            _chartImage!,
                            fit: BoxFit.contain,
                          ),
              ),
            ),
          ),

          // Bottom box for today's transactions
          Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Title for today's transactions
      const Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: Text(
          "Today's Transactions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Card for today's transactions
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: _isLoadingTransactions
              ? const Center(child: CircularProgressIndicator())
              : _todayTransactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions found for today',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todayTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _todayTransactions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction['content'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Amount: ${transaction['amount']} ${transaction['currency']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${transaction['category']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    ],
  ),
),
        ],
      ),
    );
  }
}
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  Uint8List? _chartImage;
  bool _isLoading = true;

  // Function to fetch the pie chart image
  Future<void> fetchPieChart(String chartType) async {
  try {
    // Step 1: Fetch transactions from '/transactions'
    final transactionsResponse = await http.get(Uri.parse('http://127.0.0.1:8000/transactions'));
    if (transactionsResponse.statusCode != 200) {
      throw Exception('Failed to fetch transactions');
    }

    // Parse the transactions data
    final List<dynamic> transactions = json.decode(transactionsResponse.body);
    print('Fetched transactions: $transactions');

    // Step 2: Send transactions to '/pie_chart' via POST
    final pieChartResponse = await http.post(
      Uri.parse('http://127.0.0.1:8000/pie_chart'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'transactions': transactions, // Send transactions as JSON
        'chartType': chartType.toString(),       // Include the additional parameter
      }), // Send transactions as JSON
    );

    if (pieChartResponse.statusCode == 200) {
      setState(() {
        _chartImage = pieChartResponse.bodyBytes; // Get the image bytes
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load pie chart');
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print('Error fetching pie chart: $e');
  }
}

  @override
  void initState() {
    super.initState();
    fetchPieChart('category'); // Fetch the pie chart when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show a loading spinner while fetching data
          : _chartImage == null
              ? const Center(
                  child: Text(
                    'Failed to load pie chart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ) // Show an error message if the chart fails to load
              : Center(
                  child: Image.memory(
                    _chartImage!,
                    fit: BoxFit.contain,
                  ),
                ), // Display the pie chart
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  final Set<int> _selectedTransactions = {}; // Store indices of selected transactions

  // Function to fetch transactions from the API
  Future<void> fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/transactions'));
      if (response.statusCode == 200) {
        setState(() {
          _transactions = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching transactions: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTransactions(); // Fetch transactions when the page loads
  }

  void _editSelectedTransactions() {
    // Placeholder for edit functionality
    print('Edit transactions: $_selectedTransactions');
  }

  void _deleteSelectedTransactions() {
    // Placeholder for delete functionality
    print('Delete transactions: $_selectedTransactions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _selectedTransactions.isEmpty
                ? null
                : _deleteSelectedTransactions, // Disable if no transactions are selected
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show a loading spinner while fetching data
          : _transactions.isEmpty
              ? const Center(child: Text('No transactions found')) // Show a message if no transactions are available
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    final isExpense = transaction['type'] == 'expense';
                    final amountPrefix = isExpense ? '-' : '+';
                    final amountColor = isExpense ? Colors.red : Colors.green;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              // Checkbox for selecting transactions
                              Checkbox(
                                value: _selectedTransactions.contains(index),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedTransactions.add(index);
                                    } else {
                                      _selectedTransactions.remove(index);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8), // Space between checkbox and content
                              // Amount with prefix
                              Text(
                                '$amountPrefix${transaction['amount']} ${transaction['currency']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                ),
                              ),
                              const SizedBox(width: 16), // Space between amount and content
                              // Content
                              Expanded(
                                child: Text(
                                  transaction['content'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Truncate if too long
                                ),
                              ),
                              const SizedBox(width: 16), // Space between content and category
                              // Category
                              Text(
                                transaction['category'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis, // Truncate if too long
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}



class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Settings Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class AddTransaction extends StatefulWidget {
  const AddTransaction({super.key});

  @override
  _AddTransactionState createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  String _displayText = 'This is ka stateful widget!';

  void _updateText() {
    setState(() {
      _displayText = 'The text has been updated!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_displayText),
        ElevatedButton(
          onPressed: _updateText,
          child: const Text('Update Text'),
        ),
      ],
    );
  }
}

class SecondRoute extends StatefulWidget {
  const SecondRoute({super.key});

  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  final _formKey = GlobalKey<FormState>();
  // Text editing controllers
  final TextEditingController textController1 = TextEditingController();
  final TextEditingController textController2 = TextEditingController();
  final TextEditingController textController3 = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController finalTextController = TextEditingController();

  // Drop-down values
  Map<String, String>? dropdownValue0;
  String? dropdownValue1;
  String? dropdownValue2;
  String? dropdownValue3;

  // Currency data
  final List<Map<String, String>> _currencies = [
    {'flag': '🇺🇸', 'code': 'USD'},
    {'flag': '🇪🇺', 'code': 'EUR'},
    {'flag': '🇻🇳', 'code': 'VND'},
    {'flag': '🇸🇬', 'code': 'SGD'},
    {'flag': '🇬🇧', 'code': 'GBP'},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    final url = Uri.parse('http://127.0.0.1:8000/addTransaction');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'content': textController1.text,
        'currency': dropdownValue0!['code'],
        'amount': textController2.text,
        'type': dropdownValue1,
        'date': dateController.text,
        'category': dropdownValue2,
        'tags': dropdownValue3,
        'notes': finalTextController.text,
      }),
    );

    if (response.statusCode == 200) {
      // Handle successful submission
      print(response);
    } else {
      // Handle error
      print('Failed to submit form');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: textController1,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  // Currency Dropdown
                  Expanded(
                    flex: 1, // Adjusts the width ratio for dropdown
                    child: DropdownButtonFormField<Map<String, String>>(
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: _currencies
                          .map((currency) => DropdownMenuItem(
                                value: currency,
                                child: Row(
                                  children: [
                                    Text(currency['flag']!),
                                    SizedBox(width: 8),
                                    Text(currency['code']!),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        dropdownValue0 = value;
                      },
                      validator: (value) =>
                          value == null ? 'Please select a currency' : null,
                      selectedItemBuilder: (context) => _currencies
                          .map((currency) => Row(
                                children: [
                                  Text(currency['flag']!),
                                  SizedBox(width: 8),
                                  Text(currency['code']!),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                  SizedBox(width: 10), // Margin between dropdown and text field
                  // Amount Text Field
                  Expanded(
                    flex: 3, // Adjusts the width ratio for text field
                    child: TextFormField(
                      controller: textController2,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final n = num.tryParse(value);
                        if (n == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: ['income', 'expense']
                    .map((option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    dropdownValue1 = value; // Update dropdownValue1 when a new value is selected
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select the transaction type' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Select Date',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Food & Drinks', '2', '3']
                    .map((option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    dropdownValue2 = value; // Update dropdownValue1 when a new value is selected
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Tags',
                  border: OutlineInputBorder(),
                ),
                items: ['Personal', '5', '6']
                    .map((option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    dropdownValue3 = value; // Update dropdownValue1 when a new value is selected
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a tag' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: finalTextController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const Home()));
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side: BorderSide(color: const Color.fromRGBO(255, 203, 54, 244)),
                        ),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Handle form submission here
                        _submitForm();
                        print('Form submitted');
                      }
                    },
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                      backgroundColor: MaterialStateProperty.all<Color>(const Color.fromARGB(255, 203, 54, 244)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side: BorderSide(color: const Color.fromARGB(255, 203, 54, 244)),
                        ),
                      ),
                    ),
                    child: Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}