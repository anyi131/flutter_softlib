import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_softlib/app/utils/lzy_line.dart';

void main() {
  group('LzyLine.issuedAt', () {
    test('真实的失败直链（2026-11-03 00:23 签发）', () {
      const u = 'https://h1052.lanosso.com/de35bff1d9e7c0934c70862709f8b04e'
          '/6ae8bff6/2026/10/28/1b167b7db710a26e04fd17c6a4c73d1e.apk';
      expect(LzyLine.issuedAt(u), 1793638390);
    });

    test('路径日期段不能被误当成签发时间', () {
      const u = 'https://h1060.lanosso.com/6d13825bea0f4fea937e4c7474b086e1'
          '/6ae925e0/2026/11/02/ca93f5466baa8b08a3bf3158f825142e.apk';
      final at = LzyLine.issuedAt(u);
      expect(at, 1793664480);
      expect(at, isNot(1793664000)); // 2026/11/02 日期段
    });

    test('?e= 形式的老直链', () {
      expect(LzyLine.issuedAt('https://x.com/a.apk?e=1793700000'), 1793700000);
    });

    test('读不出时间返回 0（不能瞎猜）', () {
      expect(LzyLine.issuedAt('https://example.com/f/abc12345/'), 0);
      expect(LzyLine.issuedAt(''), 0);
      expect(LzyLine.issuedAt('not a url'), 0);
    });

    test('remainSec：过期直链返回负数，新鲜直链 ≈ 1800', () {
      // 2026-11-03 00:23:10 签发 → 早已过期
      const oldUrl = 'https://h1052.lanosso.com/de35bff1d9e7c0934c70862709f8b04e'
          '/6ae8bff6/2026/10/28/1b167b7db710a26e04fd17c6a4c73d1e.apk';
      expect(LzyLine.remainSec(oldUrl), lessThan(0));
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final fresh =
          'https://h1060.lanosso.com/${'a' * 32}/${now.toRadixString(16)}'
          '/2026/11/02/${'b' * 32}.apk';
      final left = LzyLine.remainSec(fresh);
      expect(left, greaterThan(1700));
      expect(left, lessThanOrEqualTo(1800));
    });

    test('节点池里不能有 DNS 已死的 h1056 / h1062', () {
      expect(LzyLine.hosts.contains('h1056'), isFalse);
      expect(LzyLine.hosts.contains('h1062'), isFalse);
      expect(LzyLine.hosts.length, greaterThanOrEqualTo(10));
    });
  });
}
