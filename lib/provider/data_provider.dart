import 'package:flutter/cupertino.dart';
import 'package:qr_reader_flutter/entity/person.dart';
import 'package:intl/src/intl/date_format.dart';


import '../db/database.dart';
import '../main.dart';

class DataProvider extends ChangeNotifier {
  AppDatabase database = locator<AppDatabase>();

  List<Person>? qrList = [];

  Future<void> getInfo() async {
    List<Person>? response = await database.personDao.findAllPersons();
    if(response != null){
      qrList = response;
    }else{
      qrList = [];
    }
    notifyListeners();
  }

  Future<void> saveData(Person person) async {
    person.date = DateFormat('dd MMM, yyyy').format(DateTime.now());

    var response = await database.personDao.insertPerson(person);
    getInfo();
  }

}