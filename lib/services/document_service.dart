class DocumentService {
  Future<void> submitIyzicoDocuments({
    required String businessId,
    required Map<String, dynamic> docsMeta,
  }) async {
    // Şimdilik noop (sonra iyzico RPC ile bağlayacağız)
    await Future.delayed(const Duration(milliseconds: 250));
  }
}
