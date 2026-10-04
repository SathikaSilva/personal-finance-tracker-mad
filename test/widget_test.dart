import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/models/subscription.dart';
import 'package:personal_finance_tracker/services/currency_api_service.dart';
import 'package:personal_finance_tracker/widgets/category_badge.dart';

void main() {
  group('Subscription Model Unit Tests', () {
    test('Subscription toMap and fromMap serialization', () {
      final sub = Subscription(
        id: 'sub123',
        name: 'Netflix',
        category: 'Entertainment',
        monthlyCost: 9.99,
        currency: 'USD',
        renewalDate: '2026-10-15',
        receiptUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        createdAt: '2026-09-20T12:00:00.000Z',
      );

      final map = sub.toMap();
      expect(map['name'], 'Netflix');
      expect(map['category'], 'Entertainment');
      expect(map['monthlyCost'], 9.99);
      expect(map['currency'], 'USD');
      expect(map['renewalDate'], '2026-10-15');
      expect(map['receiptUrl'], 'https://res.cloudinary.com/demo/image/upload/sample.jpg');

      final reconstructed = Subscription.fromMap('sub123', map);
      expect(reconstructed.id, 'sub123');
      expect(reconstructed.name, 'Netflix');
      expect(reconstructed.category, 'Entertainment');
      expect(reconstructed.monthlyCost, 9.99);
      expect(reconstructed.currency, 'USD');
      expect(reconstructed.renewalDate, '2026-10-15');
      expect(reconstructed.receiptUrl, 'https://res.cloudinary.com/demo/image/upload/sample.jpg');
    });

    test('Subscription copyWith produces correct updated object', () {
      final sub = Subscription(
        id: 'sub1',
        name: 'Spotify',
        category: 'Music',
        monthlyCost: 500.0,
        currency: 'LKR',
        renewalDate: '2026-11-01',
        createdAt: '2026-09-20',
      );

      final updated = sub.copyWith(
        monthlyCost: 650.0,
        category: 'Entertainment',
      );

      expect(updated.id, 'sub1');
      expect(updated.name, 'Spotify');
      expect(updated.monthlyCost, 650.0);
      expect(updated.category, 'Entertainment');
      expect(updated.currency, 'LKR');
    });
  });

  group('CategoryHelper Unit Tests', () {
    test('Contains exactly 9 categories', () {
      expect(CategoryHelper.categories.length, 9);
      expect(CategoryHelper.categories, contains('Entertainment'));
      expect(CategoryHelper.categories, contains('Music'));
      expect(CategoryHelper.categories, contains('Health'));
      expect(CategoryHelper.categories, contains('Education'));
      expect(CategoryHelper.categories, contains('AI Tools'));
      expect(CategoryHelper.categories, contains('Bills'));
      expect(CategoryHelper.categories, contains('Cloud Storage'));
      expect(CategoryHelper.categories, contains('Gaming'));
      expect(CategoryHelper.categories, contains('Other'));
    });
  });

  group('CurrencyApiService Unit Tests', () {
    test('LKR to LKR returns 1.0 without network call', () async {
      final rate = await CurrencyApiService.getExchangeRateToLkr('LKR');
      expect(rate, 1.0);

      final converted = await CurrencyApiService.convertToLkr(1500, 'LKR');
      expect(converted, 1500.0);
    });

    test('Supported currencies list includes LKR, USD, EUR, GBP, AUD, INR', () {
      expect(CurrencyApiService.supportedCurrencies, contains('LKR'));
      expect(CurrencyApiService.supportedCurrencies, contains('USD'));
      expect(CurrencyApiService.supportedCurrencies, contains('EUR'));
      expect(CurrencyApiService.supportedCurrencies, contains('GBP'));
      expect(CurrencyApiService.supportedCurrencies, contains('AUD'));
      expect(CurrencyApiService.supportedCurrencies, contains('INR'));
    });
  });
}
