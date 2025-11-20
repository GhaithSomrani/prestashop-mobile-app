import 'package:flutter/foundation.dart';
import '../models/country.dart';
import '../models/ps_state.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService;

  LocationProvider(this._locationService);

  List<Country> _countries = [];
  List<PsState> _states = [];
  bool _isLoading = false;
  String? _error;

  List<Country> get countries => _countries;
  List<PsState> get states => _states;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> fetchCountries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _countries = await _locationService.getCountries();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching countries: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStatesByCountry(String countryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _states = await _locationService.getStatesByCountry(countryId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _states = [];
      if (kDebugMode) {
        print('Error fetching states: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Country? getCountryById(String id) {
    try {
      return _countries.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  PsState? getStateById(String id) {
    try {
      return _states.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearStates() {
    _states = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
