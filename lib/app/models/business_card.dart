
class BusinessCard {
  final String id;
  final String address;
  final String? imgURL;

  const BusinessCard({required this.id, required this.address, this.imgURL});

  factory BusinessCard.fromSupabase(Map<String, dynamic> u) {
    return BusinessCard(
      id: u['id'] as String,
      address: u['address'] as String,
      imgURL: u['imageURL'] as String?
    );
  }
}