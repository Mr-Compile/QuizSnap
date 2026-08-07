import '../database/database.dart';

class FolderRepository {
  final AppDatabase _database;

  FolderRepository(this._database);

  Future<List<Folder>> getAllFolders() => _database.getAllFolders();

  Future<Folder> getFolderById(int id) => _database.getFolderById(id);

  Future<int> createFolder(FoldersCompanion folder) => _database.createFolder(folder);

  Future<bool> updateFolder(Folder folder) => _database.updateFolder(folder);

  Future<void> deleteFolder(int id) => _database.deleteFolder(id);

  Future<void> restoreFolder(int id) => _database.restoreFolder(id);

  Future<List<Folder>> getDeletedFolders() => _database.getDeletedFolders();

  Future<int> permanentlyDeleteFolder(int id) => _database.permanentlyDeleteFolder(id);

  Future<List<Folder>> searchFolders(String query) => _database.searchFolders(query);
}
