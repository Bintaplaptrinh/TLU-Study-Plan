import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

class SchoolNotice {
  const SchoolNotice({required this.title, required this.url});
  final String title;
  final Uri url;
}

class NoticePage {
  const NoticePage(this.items, {this.hasNext = false});
  final List<SchoolNotice> items;
  final bool hasNext;
}

class NoticeService {
  NoticeService([http.Client? client]) : _client = client ?? http.Client();
  final http.Client _client;
  static final source = Uri.parse(
    'https://tlus.edu.vn/tin-tuc-thong-bao/thong-bao',
  );

  Future<NoticePage> fetchPage([int page = 1]) async {
    final url = page == 1
        ? source
        : Uri.parse('${source.toString()}/page/$page');
    final response = await _client
        .get(url)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200)
      throw Exception('Không tải được thông báo.');
    return parsePage(utf8.decode(response.bodyBytes));
  }

  static NoticePage parsePage(String content) {
    final document = html.parse(content);
    final seen = <String>{};
    final notices = <SchoolNotice>[];
    for (final anchor in document.querySelectorAll('.post-title a[href]')) {
      final title = anchor.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final url = source.resolve(anchor.attributes['href']!);
      if (title.isEmpty ||
          url.scheme != 'https' ||
          url.host != source.host ||
          !seen.add(url.toString()))
        continue;
      notices.add(SchoolNotice(title: title, url: url));
    }
    // A changed page layout must report a retryable error, not a false empty feed.
    if (notices.isEmpty)
      throw const FormatException('Không đọc được danh sách thông báo.');
    return NoticePage(
      notices,
      hasNext:
          document.querySelector(
            'a.next.page-numbers, a.next.page-number, a[rel="next"]',
          ) !=
          null,
    );
  }

  void close() => _client.close();
}
