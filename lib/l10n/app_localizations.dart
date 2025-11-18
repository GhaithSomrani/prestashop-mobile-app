import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('fr', ''),
    Locale('en', ''),
  ];

  Future<bool> load() async {
    String jsonString = await rootBundle
        .loadString('assets/l10n/app_${locale.languageCode}.arb');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      if (value is String) {
        return MapEntry(key, value);
      }
      return MapEntry(key, '');
    });

    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Getters for common strings
  String get appTitle => translate('appTitle');
  String get home => translate('home');
  String get categories => translate('categories');
  String get cart => translate('cart');
  String get wishlist => translate('wishlist');
  String get profile => translate('profile');

  String get search => translate('search');
  String get searchProducts => translate('searchProducts');
  String get searchHint => translate('searchHint');
  String get noResultsFound => translate('noResultsFound');
  String get searchHistory => translate('searchHistory');
  String get clearHistory => translate('clearHistory');

  String get allCategories => translate('allCategories');
  String get subcategories => translate('subcategories');
  String get viewAll => translate('viewAll');
  String get seeAll => translate('seeAll');

  String get products => translate('products');
  String get featuredProducts => translate('featuredProducts');
  String get handPickedJustForYou => translate('handPickedJustForYou');
  String get trendingToday => translate('trendingToday');
  String get newArrivals => translate('newArrivals');
  String get freshFromWarehouse => translate('freshFromWarehouse');
  String get shopByBrand => translate('shopByBrand');
  String get items => translate('items');

  String get productDetails => translate('productDetails');
  String get description => translate('description');
  String get specifications => translate('specifications');
  String get reviews => translate('reviews');
  String get addToCart => translate('addToCart');
  String get addedToCart => translate('addedToCart');
  String get buyNow => translate('buyNow');
  String get inStock => translate('inStock');
  String get outOfStock => translate('outOfStock');
  String get quantity => translate('quantity');
  String get price => translate('price');
  String get total => translate('total');
  String get subtotal => translate('subtotal');

  String get cartEmpty => translate('cartEmpty');
  String get startShopping => translate('startShopping');
  String get removeFromCart => translate('removeFromCart');
  String get clearCart => translate('clearCart');
  String get proceedToCheckout => translate('proceedToCheckout');

  String get checkout => translate('checkout');
  String get customerInformation => translate('customerInformation');
  String get shippingAddress => translate('shippingAddress');
  String get billingAddress => translate('billingAddress');
  String get shippingMethod => translate('shippingMethod');
  String get paymentMethod => translate('paymentMethod');
  String get orderSummary => translate('orderSummary');
  String get placeOrder => translate('placeOrder');

  String get firstName => translate('firstName');
  String get lastName => translate('lastName');
  String get email => translate('email');
  String get phone => translate('phone');
  String get address => translate('address');
  String get city => translate('city');
  String get state => translate('state');
  String get postalCode => translate('postalCode');
  String get country => translate('country');

  String get standardShipping => translate('standardShipping');
  String get expressShipping => translate('expressShipping');
  String get nextDayDelivery => translate('nextDayDelivery');

  String get cashOnDelivery => translate('cashOnDelivery');
  String get creditCard => translate('creditCard');
  String get paypal => translate('paypal');
  String get bankTransfer => translate('bankTransfer');

  String get orderConfirmation => translate('orderConfirmation');
  String get orderPlaced => translate('orderPlaced');
  String get orderNumber => translate('orderNumber');
  String get thankYou => translate('thankYou');
  String get orderHistory => translate('orderHistory');
  String get orderDetails => translate('orderDetails');
  String get trackOrder => translate('trackOrder');
  String get orderStatus => translate('orderStatus');

  String get login => translate('login');
  String get register => translate('register');
  String get logout => translate('logout');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get forgotPassword => translate('forgotPassword');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');

  String get myAccount => translate('myAccount');
  String get myOrders => translate('myOrders');
  String get myAddresses => translate('myAddresses');
  String get settings => translate('settings');
  String get language => translate('language');
  String get currency => translate('currency');
  String get notifications => translate('notifications');

  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get update => translate('update');
  String get confirm => translate('confirm');
  String get back => translate('back');
  String get next => translate('next');
  String get done => translate('done');
  String get ok => translate('ok');
  String get yes => translate('yes');
  String get no => translate('no');

  String get loading => translate('loading');
  String get loadingProducts => translate('loadingProducts');
  String get loadingCategories => translate('loadingCategories');
  String get error => translate('error');
  String get errorOccurred => translate('errorOccurred');
  String get tryAgain => translate('tryAgain');
  String get retry => translate('retry');

  String get sale => translate('sale');
  String get summerSale => translate('summerSale');
  String get upToOff => translate('upToOff');
  String get shopNow => translate('shopNow');

  String get filters => translate('filters');
  String get applyFilters => translate('applyFilters');
  String get sortBy => translate('sortBy');
  String get priceRange => translate('priceRange');
  String get minPrice => translate('minPrice');
  String get maxPrice => translate('maxPrice');
  String get apply => translate('apply');
  String get reset => translate('reset');

  String get brand => translate('brand');
  String get color => translate('color');
  String get size => translate('size');
  String get availability => translate('availability');
  String get onSale => translate('onSale');

  String get newest => translate('newest');
  String get priceLowToHigh => translate('priceLowToHigh');
  String get priceHighToLow => translate('priceHighToLow');
  String get popular => translate('popular');

  String get discount => translate('discount');
  String get off => translate('off');

  String get required => translate('required');
  String get invalidEmail => translate('invalidEmail');
  String get fieldRequired => translate('fieldRequired');

  String get deliveryTime => translate('deliveryTime');
  String get days => translate('days');
  String get free => translate('free');

  String get tnd => translate('tnd');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
