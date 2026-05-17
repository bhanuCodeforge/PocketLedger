import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// Base class for all repositories. Provides a typed reference to the DB.
abstract class BaseRepository {
  Future<Database> get db => DatabaseHelper.instance.database;
}
