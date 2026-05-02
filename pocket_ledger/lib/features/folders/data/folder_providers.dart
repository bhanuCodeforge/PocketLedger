import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'folder.dart';
import 'folder_repository.dart';

final folderRepositoryProvider = Provider<FolderRepository>(
  (_) => FolderRepository(),
);

final foldersProvider = FutureProvider<List<Folder>>((ref) {
  final repo = ref.watch(folderRepositoryProvider);
  return repo.getFolderTree();
});

final activeFoldersProvider = FutureProvider<List<Folder>>((ref) {
  final repo = ref.watch(folderRepositoryProvider);
  return repo.getActiveFolders();
});
