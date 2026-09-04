/// Một thư trong hộp thư trường, đúng phần Microsoft Graph trả về mà giao
/// diện cần đến. Cố tình không giữ nguyên JSON thô: Graph trả về rất nhiều
/// trường, còn màn hình Thông báo chỉ hiển thị thẻ và nội dung.
class MailMessage {
  const MailMessage({
    required this.id,
    required this.subject,
    required this.senderName,
    required this.senderAddress,
    required this.preview,
    required this.receivedAt,
    required this.isRead,
    required this.hasAttachments,
    this.importance = 'normal',
    this.bodyHtml,
    this.bodyText,
    this.toRecipients = const <String>[],
    this.webLink,
  });

  final String id;
  final String subject;
  final String senderName;
  final String senderAddress;

  /// Đoạn xem trước Graph tự cắt sẵn (`bodyPreview`) - hiện dưới tiêu đề
  /// trên thẻ, khỏi phải tải cả thân thư cho danh sách.
  final String preview;

  final DateTime receivedAt;
  final bool isRead;
  final bool hasAttachments;
  final String importance;

  /// Chỉ có sau khi gọi `fetchMessage` - danh sách không tải thân thư.
  final String? bodyHtml;
  final String? bodyText;

  final List<String> toRecipients;
  final String? webLink;

  bool get isUnread => !isRead;

  /// Tiêu đề rỗng vẫn phải hiện được gì đó trên thẻ.
  String get displaySubject =>
      subject.trim().isEmpty ? '(Không có tiêu đề)' : subject.trim();

  String get displaySender =>
      senderName.trim().isEmpty ? senderAddress : senderName.trim();

  /// Chữ cái đầu cho vòng tròn avatar của người gửi.
  String get senderInitial {
    final source = displaySender.trim();
    if (source.isEmpty) return '?';
    return source[0].toUpperCase();
  }

  factory MailMessage.fromJson(Map<String, dynamic> json) {
    // Graph lồng người gửi hai tầng: from → emailAddress → {name, address}.
    // `from` vắng mặt ở thư nháp hệ thống, nên phải chịu được null ở mọi tầng.
    final from = json['from'] ?? json['sender'];
    final email = (from is Map) ? from['emailAddress'] : null;

    final body = json['body'];
    final contentType =
        (body is Map ? body['contentType'] : null)?.toString().toLowerCase();
    final content = (body is Map ? body['content'] : null)?.toString();

    return MailMessage(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      senderName: (email is Map ? email['name'] : null)?.toString() ?? '',
      senderAddress:
          (email is Map ? email['address'] : null)?.toString() ?? '',
      preview: json['bodyPreview']?.toString() ?? '',
      receivedAt:
          DateTime.tryParse(json['receivedDateTime']?.toString() ?? '')
                  ?.toLocal() ??
              DateTime.now(),
      isRead: json['isRead'] == true,
      hasAttachments: json['hasAttachments'] == true,
      importance: json['importance']?.toString() ?? 'normal',
      bodyHtml: contentType == 'html' ? content : null,
      bodyText: contentType == 'text' ? content : null,
      toRecipients: _addresses(json['toRecipients']),
      webLink: json['webLink']?.toString(),
    );
  }

  static List<String> _addresses(dynamic list) {
    if (list is! List) return const <String>[];
    return [
      for (final item in list)
        if (item is Map && item['emailAddress'] is Map)
          (item['emailAddress']['address']?.toString() ?? '')
    ]..removeWhere((e) => e.isEmpty);
  }

  MailMessage copyWith({
    bool? isRead,
    String? bodyHtml,
    String? bodyText,
    List<String>? toRecipients,
  }) {
    return MailMessage(
      id: id,
      subject: subject,
      senderName: senderName,
      senderAddress: senderAddress,
      preview: preview,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
      hasAttachments: hasAttachments,
      importance: importance,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      bodyText: bodyText ?? this.bodyText,
      toRecipients: toRecipients ?? this.toRecipients,
      webLink: webLink,
    );
  }
}

/// Tệp đính kèm. Chỉ đại diện cho `#microsoft.graph.fileAttachment`; thư mời
/// họp và thư đính kèm thư khác (item/reference attachment) vẫn hiện tên
/// nhưng không tải được, [isFile] cho biết điều đó.
class MailAttachment {
  const MailAttachment({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.contentType,
    required this.isFile,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final String contentType;
  final bool isFile;

  factory MailAttachment.fromJson(Map<String, dynamic> json) {
    final odataType = json['@odata.type']?.toString() ?? '';
    return MailAttachment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'tệp đính kèm',
      sizeBytes: (json['size'] is num) ? (json['size'] as num).toInt() : 0,
      contentType: json['contentType']?.toString() ?? '',
      isFile: odataType.contains('fileAttachment'),
    );
  }

  /// "820 KB", "1.4 MB" - kích thước đọc được trên thẻ đính kèm.
  String get readableSize {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Phần mở rộng viết thường, không có dấu chấm.
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }
}
