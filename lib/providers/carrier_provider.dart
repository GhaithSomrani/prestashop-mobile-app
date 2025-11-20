import 'package:flutter/foundation.dart';
import '../models/carrier.dart';
import '../services/carrier_service.dart';

class CarrierProvider with ChangeNotifier {
  final CarrierService _carrierService;

  CarrierProvider(this._carrierService);

  List<Carrier> _carriers = [];
  Carrier? _selectedCarrier;
  bool _isLoading = false;
  String? _error;

  List<Carrier> get carriers => _carriers;
  Carrier? get selectedCarrier => _selectedCarrier;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasCarriers => _carriers.isNotEmpty;

  Future<void> fetchCarriers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _carriers = await _carrierService.getCarriers();

      // Set default selected carrier
      if (_selectedCarrier == null && _carriers.isNotEmpty) {
        _selectedCarrier = _carriers.first;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching carriers: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Carrier?> getCarrierById(String carrierId) async {
    try {
      // Check local first
      final local = _carriers.firstWhere(
        (c) => c.id == carrierId,
        orElse: () => throw Exception('Not found locally'),
      );
      return local;
    } catch (_) {
      // Fetch from API
      return await _carrierService.getCarrierById(carrierId);
    }
  }

  void selectCarrier(Carrier carrier) {
    _selectedCarrier = carrier;
    notifyListeners();
  }

  void selectCarrierById(String carrierId) {
    final carrier = _carriers.firstWhere(
      (c) => c.id == carrierId,
      orElse: () => _carriers.first,
    );
    _selectedCarrier = carrier;
    notifyListeners();
  }

  double getShippingCost() {
    return _selectedCarrier?.price ?? 0.0;
  }

  String getDeliveryTime() {
    return _selectedCarrier?.deliveryTime ?? 'N/A';
  }

  void clearSelection() {
    _selectedCarrier = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _carriers = [];
    _selectedCarrier = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
