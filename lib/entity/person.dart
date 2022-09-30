import 'package:floor/floor.dart';

@entity
class Person {
  @primaryKey
   int? id;
   String? date;
   String? name;
   String? email;
   String? url;
   String? phone;

  Person({this.id, this.date, this.name, this.email, this.url, this.phone});

}
