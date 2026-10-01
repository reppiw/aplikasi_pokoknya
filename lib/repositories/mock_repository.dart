import '../models/category_model.dart';
import '../models/item_model.dart';
import '../models/user_profile_model.dart';

class MockRepository {
  // 5 Record Referensi/Kategori
  final List<Category> categories = [
    Category(id: 'cat_1', name: 'Ruang Kuliah'),
    Category(id: 'cat_2', name: 'Laboratorium'),
    Category(id: 'cat_3', name: 'Auditorium'),
    Category(id: 'cat_4', name: 'Ruang Rapat'),
    Category(id: 'cat_5', name: 'Fasilitas Olahraga'),
  ];

  // 20 Record Utama
  late List<ItemData> items;

  // Profil pengguna bawaan
  UserProfile userProfile = UserProfile(
    name: 'Nabila Syahri',
    email: 'nabilasyahri@gmail.com',
    role: 'Mahasiswa',
    bio: 'Pengembang Frontend Aplikasi Pokoknya',
    notificationsEnabled: true,
  );

  MockRepository() {
    items = List.generate(
      20,
          (index) => ItemData(
        id: 'item_${index + 1}',
        categoryId: 'cat_${(index % 5) + 1}',
        title: 'Fasilitas Kampus #${index + 1}',
        description: 'Detail deskripsi untuk fasilitas ke-${index + 1} dengan kapasitas penuh.',
        price: (index + 1) * 15000.0,
        date: DateTime.now().subtract(Duration(days: index)),
        isActive: index % 2 == 0,
      ),
    );
  }

  // Fetch Items dengan Simulasi Loading & Error
  Future<List<ItemData>> getItems({bool simulateError = false}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (simulateError) {
      throw Exception('Simulasi gagal memuat data.');
    }
    return List<ItemData>.from(items);
  }

  // CRUD: Create
  Future<void> addItem(ItemData item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    items.add(item);
  }

  // CRUD: Update
  Future<void> updateItem(ItemData item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      items[index] = item;
    }
  }

  // CRUD: Delete
  Future<void> deleteItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    items.removeWhere((e) => e.id == id);
  }

  // Update Profile
  Future<void> updateProfile(UserProfile newProfile) async {
    await Future.delayed(const Duration(milliseconds: 600));
    userProfile = newProfile;
  }
}