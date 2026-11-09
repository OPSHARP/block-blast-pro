// Google Play Billing Service for Remove Ads Subscription ($4.99 / month)
// Compliant with Google Play Billing Library 7.x & Play Console policies

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../data/repositories/local_save_repository.dart';

class BillingService extends ChangeNotifier {
  static const String removeAdsSubscriptionId = 'remove_ads_monthly';
  static const String defaultPriceString = '\$4.99 / month';

  final LocalSaveRepository saveRepository;
  InAppPurchase? _iap;

  InAppPurchase? get _safeIap {
    if (_iap != null) return _iap;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _iap = InAppPurchase.instance;
      return _iap;
    }
    return null;
  }

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _removeAdsProduct;
  bool _isAvailable = false;
  bool _isAdsRemoved = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAvailable => _isAvailable;
  bool get isAdsRemoved => _isAdsRemoved;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;
  String get displayPrice => _removeAdsProduct?.price ?? defaultPriceString;

  BillingService({
    required this.saveRepository,
    InAppPurchase? iap,
  }) {
    if (iap != null) _iap = iap;
  }

  Future<void> initialize() async {
    // Load cached offline entitlement
    _isAdsRemoved = await saveRepository.loadAdsRemoved();
    notifyListeners();

    // Guard against unsupported platforms (Web, Windows desktop, Linux, macOS)
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('BillingService: In-App Purchases not natively supported on this platform. Fallback active.');
      _isAvailable = false;
      return;
    }

    try {
      final iapInstance = _safeIap;
      if (iapInstance == null) return;
      _isAvailable = await iapInstance.isAvailable();
      if (!_isAvailable) {
        debugPrint('BillingService: Store connection unavailable.');
        return;
      }

      // Listen to purchase stream
      _subscription = iapInstance.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          debugPrint('BillingService purchaseStream error: $error');
          _errorMessage = error.toString();
          notifyListeners();
        },
      );

      // Query products
      await queryProducts();
    } catch (e) {
      debugPrint('BillingService init error: $e');
    }
  }

  Future<void> queryProducts() async {
    if (!_isAvailable) return;
    try {
      final response = await _safeIap?.queryProductDetails({removeAdsSubscriptionId});
      if (response == null) return;
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('BillingService: Products not found: ${response.notFoundIDs}');
      }
      if (response.productDetails.isNotEmpty) {
        _removeAdsProduct = response.productDetails.firstWhere(
          (p) => p.id == removeAdsSubscriptionId,
          orElse: () => response.productDetails.first,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('BillingService queryProductDetails error: $e');
    }
  }

  Future<bool> buyRemoveAds() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // For testing on desktop/web or when mock store is used
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS) || !_isAvailable) {
      // Simulate successful test purchase on desktop/web
      await setAdsRemoved(true);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final product = _removeAdsProduct;
      PurchaseParam purchaseParam;

      if (product != null) {
        if (!kIsWeb && Platform.isAndroid && product is GooglePlayProductDetails) {
          purchaseParam = GooglePlayPurchaseParam(
            productDetails: product,
          );
        } else {
          purchaseParam = PurchaseParam(productDetails: product);
        }
      } else {
        // Fallback placeholder product details
        final mockDetails = ProductDetails(
          id: removeAdsSubscriptionId,
          title: 'Block Blast Pro Remove Ads (Monthly)',
          description: 'Ad-free experience with unlimited gameplay',
          price: defaultPriceString,
          rawPrice: 4.99,
          currencyCode: 'USD',
        );
        purchaseParam = PurchaseParam(productDetails: mockDetails);
      }

      // Google Play Billing subscription purchase
      final success = await _safeIap?.buyNonConsumable(purchaseParam: purchaseParam) ?? false;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      debugPrint('BillingService buyRemoveAds exception: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS) || !_isAvailable) {
      _isAdsRemoved = await saveRepository.loadAdsRemoved();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _safeIap?.restorePurchases();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('BillingService restorePurchases exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setAdsRemoved(bool removed) async {
    _isAdsRemoved = removed;
    await saveRepository.saveAdsRemoved(removed);
    notifyListeners();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoading = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _errorMessage = purchaseDetails.error?.message ?? 'Purchase failed';
          _isLoading = false;
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Verify product ID
          if (purchaseDetails.productID == removeAdsSubscriptionId) {
            await setAdsRemoved(true);
          }
          _isLoading = false;
        }

        // Complete purchase acknowledgement to prevent 3-day refund
        if (purchaseDetails.pendingCompletePurchase) {
          try {
            await _safeIap?.completePurchase(purchaseDetails);
          } catch (e) {
            debugPrint('BillingService completePurchase error: $e');
          }
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
