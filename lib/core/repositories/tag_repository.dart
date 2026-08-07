import '../database/database.dart';

class TagRepository {
  final AppDatabase _database;

  TagRepository(this._database);

  Future<List<Tag>> getAllTags() => _database.getAllTags();

  Future<Tag> getTagById(int id) => _database.getTagById(id);

  Future<int> createTag(TagsCompanion tag) => _database.createTag(tag);

  Future<bool> updateTag(Tag tag) => _database.updateTag(tag);

  Future<int> deleteTag(int id) => _database.deleteTag(id);

  Future<List<Tag>> getTagsForFlashcard(int flashcardId) => _database.getTagsForFlashcard(flashcardId);

  Future<void> addTagToFlashcard(int flashcardId, int tagId) => _database.addTagToFlashcard(flashcardId, tagId);

  Future<void> removeTagFromFlashcard(int flashcardId, int tagId) => _database.removeTagFromFlashcard(flashcardId, tagId);

  Future<void> setFlashcardTags(int flashcardId, List<int> tagIds) => _database.setFlashcardTags(flashcardId, tagIds);
}
