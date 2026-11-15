/// Shipping request model used by both user (/shipping/mine) and admin (/admin/shipping) endpoints.
class ShippingRequest {
  const ShippingRequest({
    required this.shippingId,
    required this.claimId,
    required this.itemName,
    required this.city,
    required this.address,
    required this.phone,
    this.notes,
    required this.status,
    required this.statusLabel,
    this.carrier,
    this.trackingNumber,
    this.adminNote,
    required this.createdAt,
    this.userName,
    this.userPhone,
  });

  final int shippingId;
  final int claimId;
  final String itemName;
  final String city;
  final String address;
  final String phone;
  final String? notes;
  final String status;
  final String statusLabel;
  final String? carrier;
  final String? trackingNumber;
  final String? adminNote;
  final String createdAt;
  final String? userName;
  final String? userPhone;

  int get id => shippingId;

  factory ShippingRequest.fromJson(Map<String, dynamic> j) {
    final user = j['user'] is Map ? (j['user'] as Map).cast<String, dynamic>() : null;
    return ShippingRequest(
      shippingId: (j['shipping_id'] as num?)?.toInt() ?? 0,
      claimId: (j['claim_id'] as num?)?.toInt() ?? 0,
      itemName: '${j['item_name'] ?? ''}',
      city: '${j['city'] ?? ''}',
      address: '${j['address'] ?? ''}',
      phone: '${j['phone'] ?? ''}',
      notes: j['notes'] as String?,
      status: '${j['status'] ?? ''}',
      statusLabel: '${j['status_label'] ?? j['status'] ?? ''}',
      carrier: j['carrier'] as String?,
      trackingNumber: j['tracking_number'] as String?,
      adminNote: j['admin_note'] as String?,
      createdAt: '${j['created_at'] ?? ''}',
      userName: user != null ? '${user['full_name'] ?? ''}' : (j['user_name'] as String?),
      userPhone: user != null ? '${user['phone'] ?? ''}' : (j['user_phone'] as String?),
    );
  }
}
