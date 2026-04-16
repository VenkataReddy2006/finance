import 'package:hive_flutter/hive_flutter.dart';
import '../models/person.dart';
import '../models/payment.dart';
import '../models/group.dart';

class HiveService {
  static const String peopleBox = 'people';
  static const String groupsBox = 'groups';
  static const String settingsBoxName = 'settings';

  static Box get settingsBox => Hive.box(settingsBoxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PersonAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PaymentAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(GroupAdapter());
    }

    // Open Boxes
    await Hive.openBox<Person>(peopleBox);
    await Hive.openBox<Group>(groupsBox);
    await Hive.openBox(settingsBoxName);
  }

  // --- Group Methods ---

  static List<Group> getAllGroups() {
    final box = Hive.box<Group>(groupsBox);
    return box.values.toList();
  }

  static Future<void> saveGroup(Group group) async {
    final box = Hive.box<Group>(groupsBox);
    await box.put(group.id, group);
  }

  static Future<void> deleteGroup(String id) async {
    final box = Hive.box<Group>(groupsBox);
    await box.delete(id);
  }

  // --- Person Methods ---

  static List<Person> getAllPeople() {
    final box = Hive.box<Person>(peopleBox);
    return box.values.toList();
  }

  static Future<void> savePerson(Person person) async {
    final box = Hive.box<Person>(peopleBox);
    await box.put(person.id, person);
  }

  static Future<void> deletePerson(String id) async {
    final box = Hive.box<Person>(peopleBox);
    await box.delete(id);
  }

  // --- Utility ---

  static Future<void> clearAll() async {
    await Hive.box<Group>(groupsBox).clear();
    await Hive.box<Person>(peopleBox).clear();
    await Hive.box(settingsBoxName).clear();
  }
}
