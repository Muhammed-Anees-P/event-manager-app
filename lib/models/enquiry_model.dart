enum EnquiryStatus { newEnquiry, quoted, followUp, contacted }

extension EnquiryStatusExtension on EnquiryStatus {
  String get displayName {
    switch (this) {
      case EnquiryStatus.newEnquiry:
        return 'New';
      case EnquiryStatus.quoted:
        return 'Quoted';
      case EnquiryStatus.followUp:
        return 'Follow up';
      case EnquiryStatus.contacted:
        return 'Contacted';
    }
  }
}

class EnquiryModel {
  final String id;
  final String name;
  final String phone;
  final String type;
  final String totalDate;
  final double amount;
  final EnquiryStatus status;

  const EnquiryModel({
    required this.id,
    required this.name,
    this.phone = '',
    required this.type,
    required this.totalDate,
    required this.amount,
    required this.status,
  });
}
