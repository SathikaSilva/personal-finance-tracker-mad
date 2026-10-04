import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple External API Service
/// 1. Currency Exchange API: converts USD, EUR, etc. into LKR
/// 2. Daily Tip API: fetches daily advice for the dashboard
class CurrencyApiService {
  // List of currencies for the dropdown
  static const List<String> supportedCurrencies = [
    'LKR',
    'USD',
    'EUR',
    'GBP',
    'AUD',
    'INR',
  ];

  // Cache to store rates so we don't repeat network calls
  static final Map<String, double> _cachedRates = {};

  // Simple function to get exchange rate to LKR using HTTP GET
  static Future<double> getExchangeRateToLkr(String fromCurrency) async {
    final currency = fromCurrency.toUpperCase().trim();

    // If already LKR, rate is 1.0 (no network call needed)
    if (currency == 'LKR') {
      return 1.0;
    }

    // Check cache first
    if (_cachedRates.containsKey(currency)) {
      return _cachedRates[currency]!;
    }

    try {
      // 1. Send HTTP GET request to external currency exchange API
      final url = Uri.parse('https://open.er-api.com/v6/latest/$currency');
      final response = await http.get(url);

      // 2. Check status code and parse JSON response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rates'] != null && data['rates']['LKR'] != null) {
          final rate = (data['rates']['LKR'] as num).toDouble();
          _cachedRates[currency] = rate; // save in cache
          return rate;
        }
      }
      return 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  // Convert amount to LKR
  static Future<double> convertToLkr(double amount, String fromCurrency) async {
    final rate = await getExchangeRateToLkr(fromCurrency);
    return amount * rate;
  }

  // Fetch a daily tip / advice from the external Advice API
  static Future<String> getDailyTip() async {
    try {
      final url = Uri.parse('https://api.adviceslip.com/advice');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['slip'] != null && data['slip']['advice'] != null) {
          return data['slip']['advice'].toString();
        }
      }
    } catch (e) {
      // Fallback tip if offline
    }
    return "Some of life's best lessons are learnt at the worst times.";
  }
}
