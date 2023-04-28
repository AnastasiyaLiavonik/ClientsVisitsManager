import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class Visit {
  Visit({required this.date, required this.time, required this.notes});
  DateTime date;
  String time;
  String notes;
}

class Client {
  Client({
    this.id,
    required this.name,
    required this.surname,
    required this.phoneNumber,
    this.instagramUsername,
    this.skinType,
    this.notes,
    this.visits,
  });
  int? id;
  String name;
  String surname;
  String phoneNumber;
  String? instagramUsername;
  String? skinType;
  String? notes;
  List<Visit>? visits;
}

class DatabaseHelper {
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static Database _database;

  Future<Database> get database async {
    return _database;
    _database = await initDatabase();
    return _database;
  }

  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'clients.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clients(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            surname TEXT,
            phoneNumber TEXT,
            instagramUsername TEXT,
            skinType TEXT,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE visits(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clientId INTEGER,
            date TEXT,
            time TEXT,
            notes TEXT,
            FOREIGN KEY (clientId) REFERENCES clients (id)
          )
        ''');
      },
    );
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clients');
    return List.generate(
      maps.length,
      (index) => Client(
        id: maps[index]['id'] as int,
        name: maps[index]['name'] as String,
        surname: maps[index]['surname'] as String,
        phoneNumber: maps[index]['phoneNumber'],
        instagramUsername: maps[index]['instagramUsername'],
        skinType: maps[index]['skinType'],
        notes: maps[index]['notes'],
      ),
    );
  }

  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int clientId) async {
    final db = await database;
    return await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }

  Future<List<Visit>> getVisitsForClient(int clientId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('visits', where: 'clientId = ?', whereArgs: [clientId]);
    return List.generate(
      maps.length,
      (index) => Visit(
        date: DateTime.parse(maps[index]['date']),
        time: maps[index]['time'],
        notes: maps[index]['notes'],
      ),
    );
  }

  Future<int> insertVisit(Visit visit) async {
    final db = await database;
    return await db.insert('visits', visit.toMap());
  }

  Future<int> updateVisit(Visit visit) async {
    final db = await database;
    return await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> deleteVisit(int visitId) async {
    final db = await database;
    return await db.delete(
      'visits',
      where: 'id = ?',
      whereArgs: [visitId],
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        //debugShowCheckedModeBanner: false,
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 118, 11, 18),
          ),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  WordPair current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  final favorites = <WordPair>[];
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const ClientsPage();
        break;
      case 1:
        page = const VisitsPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.person_search),
                      label: Text('Clients'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.more_time_outlined),
                      label: Text('Visits'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  _ClientsPageState createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final clients = <Client>[]; // List to store clients data

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      body: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) => ListTile(
          title: Text('${clients[index].name} ${clients[index].surname}'),
          selectedColor: theme.primaryColorDark,
          onTap: () => _showClientDetails(
            clients[index],
          ), // Show client details when tapped
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addClient, // Add client when fab is pressed
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showClientDetails(Client client) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${client.name} ${client.surname}'),
        content: Column(
          children: [
            Text('Phone Number: ${client.phoneNumber}'),
            Text('Username in Instagram: ${client.instagramUsername}'),
            Text('Type of Skin: ${client.skinType}'),
            Text('Notes: ${client.notes}'),
            const Text('History of Visits:'),
            Column(
              children: client.visits.map((visit) {
                final formattedDate =
                    DateFormat('yyyy-MM-dd hh:mm a').format(visit.dateTime);
                return ListTile(
                  title: Text('Date/Time: $formattedDate'),
                  subtitle: Text('Notes: ${visit.notes}'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _editClient(client), // Edit client details
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editClient(Client client) {
    // Code to edit client details
  }

  void addClient() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Client'),
        content: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                // Update name of the client
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Surname'),
              onChanged: (value) {
                // Update surname of the client
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
              onChanged: (value) {
                // Update phone number of the client
              },
            ),
            TextField(
              decoration:
                  const InputDecoration(labelText: 'Instagram Username'),
              onChanged: (value) {
                // Update Instagram username of the client
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Skin Type'),
              onChanged: (value) {
                // Update skin type of the client
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Notes'),
              onChanged: (value) {
                // Update notes of the client
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Create a new Client object and add it to the clients list
              final newClient = Client(
                name: '', // Update with the value from TextField
                surname: '', // Update with the value from TextField
                phoneNumber: '', // Update with the value from TextField
                instagramUsername: '', // Update with the value from TextField
                skinType: '', // Update with the value from TextField
                notes: '', // Update with the value from TextField
                visits: [], // Empty list of visits for the new client
              );
              setState(() {
                clients.add(newClient);
              });
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class Client {
  Client({
    required this.name,
    required this.surname,
    required this.phoneNumber,
    required this.instagramUsername,
    required this.skinType,
    required this.notes,
    required this.visits,
  });
  String name;
  String surname;
  String phoneNumber;
  String instagramUsername;
  String skinType;
  String notes;
  List<Visit> visits;
}

class Visit {
  Visit({required this.dateTime, required this.notes});
  DateTime dateTime;
  String notes;
}

// class ClientsPage extends StatelessWidget {
//   const ClientsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final appState = context.watch<MyAppState>();
//     final pair = appState.current;

//     IconData icon;
//     if (appState.favorites.contains(pair)) {
//       icon = Icons.favorite;
//     } else {
//       icon = Icons.favorite_border;
//     }

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           BigCard(pair: pair),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: appState.toggleFavorite,
//                 icon: Icon(icon),
//                 label: const Text('Like'),
//               ),
//               const SizedBox(width: 10),
//               ElevatedButton(
//                 onPressed: appState.getNext,
//                 child: const Text('Next'),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }

class VisitsPage extends StatefulWidget {
  const VisitsPage({super.key});

  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage> {
  final selectedIndex = 0;

  // void removeFromFavorites(int index) {
  //     setState(() {
  //       appState.favorites.removeAt(index);
  //     });
  // }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    if (appState.favorites.isEmpty) {
      return const Center(
        child: Text('No favorites yet.'),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      body: ListView.builder(
        itemCount: appState.favorites.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(appState.favorites[index].asLowerCase),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle),
              onPressed: () {
                setState(() {
                  appState.favorites.removeAt(index);
                });
                // showDialog(
                //   context: context,
                //   builder: (context) {},
                // );
              },
            ),
          );
        },
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimary);

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: '${pair.first} ${pair.second}',
        ),
      ),
    );
  }
}
