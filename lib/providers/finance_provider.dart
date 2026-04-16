import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/person.dart';
import '../models/group.dart';
import '../models/payment.dart';
import '../services/hive_service.dart';
import '../services/api_service.dart';

class FinanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Group> _groups = [];
  List<Person> _people = [];
  bool _isLoading = false;

  List<Group> get groups => _groups;
  List<Person> get people => _people;
  bool get isLoading => _isLoading;

  FinanceProvider() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        loadData();
      } else {
        // Force clear memory and LOCAL Hive on logout
        // This prevents the next user from seeing previous user's data
        _groups = [];
        _people = [];
        await HiveService.clearAll();
        notifyListeners();
      }
    });
  }

  Future<void> loadData() async {
    // 1. Load from Hive Cache immediately
    _groups = HiveService.getAllGroups();
    _people = HiveService.getAllPeople();
    notifyListeners(); // Immediate UI update with cached data

    // 2. Only show full loading spinner if cache is empty
    if (_groups.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 3. Fetch from Cloud in background
      final groupsFuture = _apiService.getGroups();
      final peopleFuture = _apiService.getPeople();
      
      final cloudGroups = await groupsFuture;
      final cloudPeople = await peopleFuture;

      // 4. Update memory only if cloud has data, otherwise sync UP from local
      if (cloudGroups.isNotEmpty) {
        _groups = cloudGroups;
        _people = cloudPeople;
        
        // Update Local Cache (Sync Down)
        await HiveService.clearAll();
        for (var g in _groups) { await HiveService.saveGroup(g); }
        for (var p in _people) { await HiveService.savePerson(p); }
      } else if (_groups.isNotEmpty) {
        // Cloud is empty, but local has data: Sync UP!
        debugPrint('Cloud empty, syncing local data to cloud...');
        await _migrateLocalToCloud();
      }
      
    } catch (e) {
      debugPrint('Background sync error: $e');
      // If error, we already have Hive data loaded above
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Migration logic for first login
  Future<void> _migrateLocalToCloud() async {
    final localGroups = HiveService.getAllGroups();
    final localPeople = HiveService.getAllPeople();

    for (var g in localGroups) {
      await _apiService.createGroup(g.name, g.id);
    }
    for (var p in localPeople) {
      await _apiService.createPerson(p);
    }
    
    _groups = await _apiService.getGroups();
    _people = await _apiService.getPeople();
  }

  // --- Group Methods ---

  Future<void> addGroup(String name) async {
    final id = const Uuid().v4();
    final newGroup = Group(id: id, name: name, orderIndex: _groups.length);
    
    // Optimistic Update
    _groups.add(newGroup);
    await HiveService.saveGroup(newGroup);
    notifyListeners();

    try {
      await _apiService.createGroup(name, id);
      debugPrint('Group synced to cloud');
    } catch (e) {
      debugPrint('Error syncing group (saved locally): $e');
      // No need to revert since it's saved locally
    }
  }

  Future<void> renameGroup(String id, String newName) async {
    final groupIndex = _groups.indexWhere((g) => g.id == id);
    if (groupIndex != -1) {
      final updatedGroup = _groups[groupIndex].copyWith(name: newName);
      try {
        _groups[groupIndex] = updatedGroup;
        await HiveService.saveGroup(updatedGroup);
        notifyListeners();
        
        await _apiService.updateGroup(updatedGroup);
        debugPrint('Group renamed in cloud');
      } catch (e) {
        debugPrint('Error renaming group: $e');
      }
    }
  }

  Future<void> deleteGroup(String id) async {
    try {
      await _apiService.deleteGroup(id);
      _groups.removeWhere((g) => g.id == id);
      _people.removeWhere((p) => p.groupId == id);
      await HiveService.deleteGroup(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting group: $e');
    }
  }

  // --- Person Methods ---

  List<Person> getPeopleForGroup(String groupId) {
    return _people.where((p) => p.groupId == groupId).toList()
      ..sort((a, b) => a.sNo.compareTo(b.sNo));
  }

  Future<void> addPerson({
    required int sNo,
    required String name,
    required String village,
    required DateTime date,
    required double principal,
    required double interest,
    required String groupId,
  }) async {
    final person = Person(
      id: const Uuid().v4(),
      sNo: sNo,
      name: name,
      village: village,
      date: date,
      principal: principal,
      interest: interest,
      groupId: groupId,
    );

    try {
      // Optimistic Update
      _people.add(person);
      await HiveService.savePerson(person);
      notifyListeners();

      await _apiService.createPerson(person);
      debugPrint('Person synced to cloud');
    } catch (e) {
      debugPrint('Error adding person (saved locally): $e');
    }
  }

  Future<void> updatePerson(Person person) async {
    try {
      final index = _people.indexWhere((p) => p.id == person.id);
      if (index != -1) {
        // Optimistic Update
        _people[index] = person;
        await HiveService.savePerson(person);
        notifyListeners();
        
        await _apiService.updatePerson(person);
        debugPrint('Person updated in cloud');
      }
    } catch (e) {
      debugPrint('Error updating person: $e');
    }
  }

  Future<void> deletePerson(String id) async {
    try {
      await _apiService.deletePerson(id);
      _people.removeWhere((p) => p.id == id);
      await HiveService.deletePerson(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting person: $e');
    }
  }

  // --- Payment Methods ---

  Future<void> addPayment(String personId, double amount, DateTime date) async {
    final paymentId = const Uuid().v4();
    final payment = Payment(id: paymentId, amount: amount, date: date);
    
    try {
      await _apiService.addPayment(personId, payment.toJson());
      
      final personIndex = _people.indexWhere((p) => p.id == personId);
      if (personIndex != -1) {
        final updatedPerson = _people[personIndex];
        updatedPerson.payments.add(payment);
        await HiveService.savePerson(updatedPerson);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding payment: $e');
    }
  }

  Future<void> deletePayment(String personId, String paymentId) async {
    try {
      await _apiService.deletePayment(personId, paymentId);
      
      final personIndex = _people.indexWhere((p) => p.id == personId);
      if (personIndex != -1) {
        final updatedPerson = _people[personIndex];
        updatedPerson.payments.removeWhere((p) => p.id == paymentId);
        await HiveService.savePerson(updatedPerson);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting payment: $e');
    }
  }

  // --- Auth Helper ---
  Future<void> resetAll() async {
    await HiveService.clearAll();
    _groups = [];
    _people = [];
    notifyListeners();
  }

  Future<void> importData(List<Person> importedPeople) async {
    _isLoading = true;
    notifyListeners();

    try {
      for (var p in importedPeople) {
        await _apiService.createPerson(p);
      }
      await loadData(); // Reload all from source of truth
    } catch (e) {
      debugPrint('Error importing data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Helper for check SN0
  bool isDuplicateSNo(String groupId, int sNo, {String? excludeId}) {
    return _people.any((p) =>
        p.groupId == groupId && p.sNo == sNo && p.id != excludeId);
  }

  // Helper for Search
  List<Person> searchPeople(String groupId, String query) {
    if (query.isEmpty) return getPeopleForGroup(groupId);
    final q = query.toLowerCase();
    return getPeopleForGroup(groupId).where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.village.toLowerCase().contains(q) ||
          p.sNo.toString().contains(q);
    }).toList();
  }

  // Totals for Dashboard
  double get weeklyBalance => _people.fold(0, (sum, p) => sum + p.balance);
  double get weeklyPrincipal => _people.fold(0, (sum, p) => sum + p.principal);
  double get weeklyInterest => _people.fold(0, (sum, p) => sum + p.interest);
  double get weeklyGiven => _people.fold(0, (sum, p) => sum + p.totalGiven);

  // Grouped Payments for list
  Map<DateTime, List<Map<String, dynamic>>> getGroupedPayments() {
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
    for (var person in _people) {
      for (var payment in person.payments) {
        final date = DateTime(payment.date.year, payment.date.month, payment.date.day);
        if (!grouped.containsKey(date)) grouped[date] = [];
        grouped[date]!.add({
          'personName': person.name,
          'amount': payment.amount,
        });
      }
    }
    return grouped;
  }

  Map<String, List<Map<String, dynamic>>> getPaymentsGroupedByGroup() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var group in _groups) {
      final groupPeople = getPeopleForGroup(group.id);
      final List<Map<String, dynamic>> groupPayments = [];
      for (var person in groupPeople) {
        for (var payment in person.payments) {
          groupPayments.add({
            'personName': person.name,
            'amount': payment.amount,
            'date': payment.date,
          });
        }
      }
      if (groupPayments.isNotEmpty) {
        groupPayments.sort((a, b) => b['date'].compareTo(a['date']));
        grouped[group.name] = groupPayments;
      }
    }
    return grouped;
  }

  Map<DateTime, List<Map<String, dynamic>>> getPaymentsGroupedByDateForGroup(String groupId) {
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
    final groupPeople = getPeopleForGroup(groupId);
    for (var person in groupPeople) {
      for (var payment in person.payments) {
        final date = DateTime(payment.date.year, payment.date.month, payment.date.day);
        if (!grouped.containsKey(date)) grouped[date] = [];
        grouped[date]!.add({
          'personName': person.name,
          'amount': payment.amount,
          'date': payment.date,
        });
      }
    }
    return grouped;
  }

  Map<String, double> getTotalCollectionsForGroup(String groupId) {
    double total = 0;
    int count = 0;
    final groupPeople = getPeopleForGroup(groupId);
    for (var person in groupPeople) {
      for (var payment in person.payments) {
        total += payment.amount;
        count++;
      }
    }
    return {'total': total, 'count': count.toDouble()};
  }

  Map<String, double> getGroupSummary(String groupId) {
    final groupPeople = getPeopleForGroup(groupId);
    double totalPrincipal = 0;
    double totalInterest = 0;
    double totalGiven = 0;
    double totalBalance = 0;
    double totalPotential = 0;

    for (var p in groupPeople) {
      totalPrincipal += p.principal;
      totalInterest += p.interest;
      totalGiven += p.totalGiven;
      totalBalance += p.balance;
      totalPotential += p.totalAmount;
    }

    return {
      'principal': totalPrincipal,
      'interest': totalInterest,
      'given': totalGiven,
      'balance': totalBalance,
      'potential': totalPotential,
      'count': groupPeople.length.toDouble(),
    };
  }
}
