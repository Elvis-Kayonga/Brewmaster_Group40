// lib/config/localization/app_localizations.dart
//
// Hand-written localization delegate for English (en), Kinyarwanda (rw),
// and Swahili (sw). No code generation required — keys are looked up from
// a static const map with English fallback.
//
// Requirements: 1.5, 5.7, 10.6, 10.7
// Developer: Developer 6

import 'package:flutter/material.dart';

/// Provides localised strings for the three supported locales.
///
/// Usage:
/// ```dart
/// final loc = AppLocalizations.of(context);
/// Text(loc.login)
/// ```
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('rw'), // Kinyarwanda
    Locale('sw'), // Swahili
  ];

  /// All keys that every locale must define.
  static const List<String> requiredKeys = [
    'app_name',
    'login',
    'sign_up',
    'email',
    'password',
    'dashboard',
    'search',
    'messages',
    'profile',
    'listings',
    'market_prices',
    'sign_out',
    'error_network',
    'error_server',
    'error_auth',
    'error_unknown',
    'error_permission',
    'retry',
    'cancel',
    'save',
    'delete',
    'confirm',
    'voice_input_hint',
    'voice_listening',
    'voice_not_available',
    'verified',
    'pending',
    'rejected',
    'get_verified',
    'shop',
    'orders',
    'prices',
    'my_store',
    'settings',
    'language',
    'appearance',
    'notifications',
    'dark_mode',
    // auth
    'welcome_back',
    'login_subtitle',
    'email_address',
    'email_required',
    'email_invalid',
    'password_required',
    'sign_in_as_buyer',
    'sign_in_as_seller',
    'forgot_password',
    'password_reset_sent',
    'please_enter_email_first',
    'or',
    'sign_in_with_google',
    'no_account',
    'create_one',
    'join_brewmaster',
    'signup_subtitle',
    'full_name',
    'name_required',
    'confirm_password',
    'please_confirm_password',
    'passwords_do_not_match',
    'sign_up_as_buyer',
    'sign_up_as_seller',
    'sign_up_with_google',
    'already_have_account',
    'sign_in',
    'i_want_to_buy',
    'i_want_to_sell',
    'buyer',
    'seller',
    'farmer',
    // profile setup
    'complete_your_profile',
    'select_your_role',
    'what_is_your_role',
    'role_help_text',
    'im_a_farmer',
    'grow_sell_coffee',
    'im_a_buyer',
    'purchase_trade_coffee',
    'farm_details',
    'business_details',
    'tell_us_about_farm',
    'tell_us_about_business',
    'country',
    'select_country',
    'farm_size_hectares',
    'farm_location',
    'coffee_varieties',
    'coffee_varieties_hint',
    'separate_with_commas',
    'farm_registration_number',
    'optional',
    'business_name',
    'business_name_hint',
    'business_type',
    'business_type_hint',
    'monthly_volume_kg',
    'save_profile',
    'please_select_role',
    'enter_valid_farm_size',
    'enter_valid_volume',
    // dashboard
    'farmer_command',
    'active_seller',
    'analytics',
    'active_lots',
    'orders_logged',
    'total_revenue',
    'velocity_command',
    'seven_day_revenue',
    'market_intelligence',
    'saved',
    'response_rate',
    'no_orders_yet',
    'confirm_delivery',
    'delivery_confirmed',
    'awaiting_payment',
    'in_escrow',
    'delivered_awaiting_confirmation',
    'completed',
    'under_dispute',
    'cancelled',
    'initialize_lot',
    'no_listings_yet',
    'my_dashboard',
    'buyer_dashboard_subtitle',
    'total_purchases',
    'conversations',
    'saved_lots',
    'quick_access',
    'browse_shop',
    'market_prices_label',
    'loading_dashboard',
    'refresh',
    // market prices
    'live_commodity_index',
    'no_market_prices',
    'loading_market_prices',
    'sync_prices',
    'low',
    'average',
    'high',
    'updated',
    // listings
    'coffee_profile',
    'processing_station',
    'specifications',
    'altitude',
    'processing',
    'harvest_year',
    'quality_score',
    'available',
    'price_per_kg',
    'farm_location_label',
    'contact_farmer',
    'this_is_your_listing',
    'create_listing',
    'edit_listing',
    'update_listing',
    'variety',
    'quantity_kg',
    'price_per_kg_usd',
    'altitude_m',
    'harvest_date',
    'quality_score_0_100',
    'description',
    'describe_your_coffee',
    'farm_location_address',
    'latitude',
    'longitude',
    'auto_filled',
    'geocode_tooltip',
    'pick_images',
    'images_selected',
    'fill_required_fields',
    'geocode_failed',
    // messaging
    'direct_messaging',
    'search_conversations',
    'no_messages_title',
    'no_messages_description',
    'no_messages_yet',
    'say_hi',
    'stop_listening',
    'speak',
    'type_a_message',
    'speech_not_available',
    'conversation',
    // notifications
    'no_notifications_title',
    'no_notifications_description',
    'mark_all_read',
    // payments
    'make_payment',
    'payment_summary',
    'amount_usd',
    'transaction_fee',
    'total_usd',
    'powered_by_flutterwave',
    'agree_terms',
    'escrow_info',
    'pay_with_flutterwave',
    'please_agree_terms',
    'fetching_rate',
    'payment_not_configured',
    'payment_cancelled',
    'payment_successful',
    'payment_error',
    'transaction_details',
    'transaction_information',
    'transaction_id',
    'buyer_label',
    'amount_label',
    'payment_method',
    'created_label',
    'retry_attempts',
    'status_timeline',
    'dispute_raised',
    'action_completed',
    'transaction_not_found',
    'pending_payment',
    'funds_held_escrow',
    'awaiting_buyer_confirmation',
    'disputed',
    'confirm_delivery_title',
    'confirm_delivery_message',
    'confirm_receipt_title',
    'confirm_receipt_message',
    'confirm_release_funds',
    'raise_dispute',
    'dispute_reason',
    'describe_issue',
    'dispute_description',
    'submit_dispute',
    'my_orders',
    'orders_subtitle',
    'no_transactions_title',
    'no_transactions_description',
    'view_all',
    'live_trace_active',
    'awaiting_payment_title',
    'in_transit',
    'delivered',
    'origin',
    'processing_step',
    'export',
    'freight',
    'delivery',
    // profile
    'profile_title',
    'email_verified',
    'email_unverified',
    'verify_email',
    'farm_details_label',
    'business_details_label',
    'farm_size',
    'location',
    'coffee_varieties_label',
    'registration_no',
    'monthly_volume',
    'not_set',
    'edit_profile',
    'loading_profile',
    'no_profile_found',
    // settings
    'using_dark_theme',
    'using_light_theme',
    'new_listings',
    'payments_label',
    'market_price_alerts',
    'preferences_saved_info',
    'messages_subtitle',
    'new_listings_subtitle',
    'payments_subtitle',
    'market_alerts_subtitle',
    // saved lots
    'saved_lots_title',
    'clear_all',
    'no_saved_lots',
    'no_saved_lots_hint',
    'price_per_kg_label',
    'kg_available',
    'message_button',
    'direct_pay',
    // search
    'direct_trade_shop',
    'shop_subtitle',
    'search_hint',
    'hide_filters',
    'advanced_filters',
    'origin_country',
    'processing_method',
    'price_range_usd',
    'altitude_range',
    'min',
    'max',
    'clear',
    'apply_filters',
    'no_listings_found',
    'try_adjusting_filters',
    'no_map_data',
    'no_map_coordinates',
    'list_view',
    'map_view',
    'removed_from_saved',
    'saved_to_wishlist',
    'view',
    'lot_rating',
    'producer',
    // voice
    'chief_curator',
    'voice_greeting',
    'initialize_session',
    'end_session',
    'chief_curator_active',
    'try_again',
    // edit profile
    'edit_profile_title',
    'display_name',
    'display_name_hint',
    'display_name_required',
    'discard_changes_title',
    'discard_changes_message',
    'discard',
    'save_changes',
    'photo_upload_failed',
  ];

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_name': 'BrewMaster',
      'login': 'Login',
      'sign_up': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'dashboard': 'Dashboard',
      'search': 'Search',
      'messages': 'Messages',
      'profile': 'Profile',
      'listings': 'Listings',
      'market_prices': 'Market Prices',
      'sign_out': 'Sign Out',
      'error_network': 'No internet connection. Please check your network.',
      'error_server': 'Server error. Please try again later.',
      'error_auth': 'Authentication failed. Please sign in again.',
      'error_unknown': 'An unexpected error occurred.',
      'error_permission': 'Permission denied.',
      'retry': 'Try again',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'voice_input_hint': 'Tap the mic to speak',
      'voice_listening': 'Listening...',
      'voice_not_available': 'Voice input not available',
      'verified': 'Verified',
      'pending': 'Pending',
      'rejected': 'Rejected',
      'get_verified': 'Get Verified',
      'shop': 'Shop',
      'orders': 'Orders',
      'prices': 'Prices',
      'my_store': 'My Store',
      'settings': 'Settings',
      'language': 'Language',
      'appearance': 'Appearance',
      'notifications': 'Notifications',
      'dark_mode': 'Dark Mode',
      // auth
      'welcome_back': 'Welcome Back',
      'login_subtitle': 'Log in to your BrewMaster account.',
      'email_address': 'Email Address',
      'email_required': 'Email is required',
      'email_invalid': 'Enter a valid email',
      'password_required': 'Password is required',
      'sign_in_as_buyer': 'Sign In as Buyer',
      'sign_in_as_seller': 'Sign In as Seller',
      'forgot_password': 'Forgot password?',
      'password_reset_sent': 'Password reset email sent.',
      'please_enter_email_first': 'Please enter your email first.',
      'or': 'OR',
      'sign_in_with_google': 'Sign in with Google',
      'no_account': "Don't have an account? ",
      'create_one': 'Create one',
      'join_brewmaster': 'Join BrewMaster',
      'signup_subtitle': 'Choose your role and start your journey.',
      'full_name': 'Full Name',
      'name_required': 'Name is required',
      'confirm_password': 'Confirm Password',
      'please_confirm_password': 'Please confirm your password',
      'passwords_do_not_match': 'Passwords do not match',
      'sign_up_as_buyer': 'Sign up as Buyer',
      'sign_up_as_seller': 'Sign up as Seller',
      'sign_up_with_google': 'Sign up with Google',
      'already_have_account': 'Already have an account? ',
      'sign_in': 'Sign In',
      'i_want_to_buy': 'I want to buy',
      'i_want_to_sell': 'I want to sell',
      'buyer': 'Buyer',
      'seller': 'Seller',
      'farmer': 'Farmer',
      // profile setup
      'complete_your_profile': 'Complete Your Profile',
      'select_your_role': 'Select Your Role',
      'what_is_your_role': 'What is your role?',
      'role_help_text': 'This helps us show you relevant features and content.',
      'im_a_farmer': "I'm a Farmer",
      'grow_sell_coffee': 'Grow and sell coffee beans',
      'im_a_buyer': "I'm a Buyer",
      'purchase_trade_coffee': 'Purchase and trade coffee',
      'farm_details': 'Farm Details',
      'business_details': 'Business Details',
      'tell_us_about_farm': 'Tell us more about your farm.',
      'tell_us_about_business': 'Tell us more about your business.',
      'country': 'Country',
      'select_country': 'Select your country',
      'farm_size_hectares': 'Farm Size (hectares)',
      'farm_location': 'Farm Location',
      'coffee_varieties': 'Coffee Varieties',
      'coffee_varieties_hint': 'e.g. Arabica, Robusta',
      'separate_with_commas': 'Separate varieties with commas',
      'farm_registration_number': 'Farm Registration Number',
      'optional': 'Optional',
      'business_name': 'Business Name',
      'business_name_hint': 'Enter your business name',
      'business_type': 'Business Type',
      'business_type_hint': 'e.g. Roaster, Exporter, Retailer',
      'monthly_volume_kg': 'Monthly Volume (kg)',
      'save_profile': 'Save Profile',
      'please_select_role': 'Please select a role (Farmer or Buyer)',
      'enter_valid_farm_size': 'Enter a valid farm size',
      'enter_valid_volume': 'Enter a valid volume',
      // dashboard
      'farmer_command': 'Farmer\nCommand',
      'active_seller': 'Active Seller | Link: Secured',
      'analytics': 'ANALYTICS',
      'active_lots': 'ACTIVE LOTS',
      'orders_logged': 'ORDERS LOGGED',
      'total_revenue': 'TOTAL REVENUE',
      'velocity_command': 'VELOCITY COMMAND',
      'seven_day_revenue': '7-day revenue',
      'market_intelligence': 'MARKET INTELLIGENCE',
      'saved': 'Saved',
      'response_rate': 'Response rate',
      'no_orders_yet': 'No orders yet.',
      'confirm_delivery': 'Confirm Delivery',
      'delivery_confirmed': 'Delivery confirmed successfully.',
      'awaiting_payment': 'Awaiting payment',
      'in_escrow': 'In escrow',
      'delivered_awaiting_confirmation': 'Delivered — awaiting confirmation',
      'completed': 'Completed',
      'under_dispute': 'Under dispute',
      'cancelled': 'Cancelled',
      'initialize_lot': '+ INITIALIZE LOT',
      'no_listings_yet':
          'No listings yet. Tap the button above to create your first lot.',
      'my_dashboard': 'My\nDashboard',
      'buyer_dashboard_subtitle': 'Your coffee purchasing activity at a glance.',
      'total_purchases': 'TOTAL PURCHASES',
      'conversations': 'CONVERSATIONS',
      'saved_lots': 'SAVED LOTS',
      'quick_access': 'QUICK ACCESS',
      'browse_shop': 'Browse\nShop',
      'market_prices_label': 'Market\nPrices',
      'loading_dashboard': 'Loading your dashboard…',
      'refresh': 'Refresh',
      // market prices
      'live_commodity_index': 'LIVE COMMODITY INDEX',
      'no_market_prices': 'No market prices available.',
      'loading_market_prices': 'Loading market prices…',
      'sync_prices': 'Sync prices',
      'low': 'Low',
      'average': 'Average',
      'high': 'High',
      'updated': 'Updated',
      // listings
      'coffee_profile': 'COFFEE PROFILE',
      'processing_station': 'PROCESSING STATION',
      'specifications': 'SPECIFICATIONS',
      'altitude': 'Altitude',
      'processing': 'Processing',
      'harvest_year': 'Harvest Year',
      'quality_score': 'Quality Score',
      'available': 'Available',
      'price_per_kg': 'Price / kg',
      'farm_location_label': 'FARM LOCATION',
      'contact_farmer': 'CONTACT FARMER',
      'this_is_your_listing': 'This is your own listing.',
      'create_listing': 'Create Listing',
      'edit_listing': 'Edit Listing',
      'update_listing': 'Update Listing',
      'variety': 'Variety',
      'quantity_kg': 'Quantity (kg)',
      'price_per_kg_usd': 'Price per kg (USD)',
      'altitude_m': 'Altitude (m)',
      'harvest_date': 'Harvest Date',
      'quality_score_0_100': 'Quality Score (0-100)',
      'description': 'Description',
      'describe_your_coffee': 'Describe your coffee',
      'farm_location_address': 'Farm Location Address *',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'auto_filled': 'Auto-filled',
      'geocode_tooltip': 'Geocode address to coordinates',
      'pick_images': 'Pick Images',
      'images_selected': 'image(s) selected',
      'fill_required_fields': 'Please fill all required fields including address',
      'geocode_failed': 'Could not find coordinates for that address.',
      // messaging
      'direct_messaging': 'DIRECT MESSAGING',
      'search_conversations': 'Search conversations...',
      'no_messages_title': 'No Messages',
      'no_messages_description':
          'Start a conversation to connect with farmers or buyers',
      'no_messages_yet': 'No messages yet',
      'say_hi':
          'Say hi! Ask about the coffee variety,\nprocessing method, or arrange a shipment.',
      'stop_listening': 'Stop listening',
      'speak': 'Speak',
      'type_a_message': 'Type a message...',
      'speech_not_available':
          'Speech recognition not available on this device.',
      'conversation': 'Conversation',
      // notifications
      'no_notifications_title': 'No notifications',
      'no_notifications_description': "You're all caught up!",
      'mark_all_read': 'Mark all read',
      // payments
      'make_payment': 'Make Payment',
      'payment_summary': 'Payment Summary',
      'amount_usd': 'Amount (USD):',
      'transaction_fee': 'Transaction Fee:',
      'total_usd': 'Total (USD):',
      'powered_by_flutterwave':
          'Powered by Flutterwave. Choose your preferred method (card, mobile money, MPESA) on the next screen.',
      'agree_terms': 'I agree to the terms and conditions of escrow payment',
      'escrow_info':
          'Your payment will be held in escrow until delivery is confirmed by both parties.',
      'pay_with_flutterwave': 'Pay with Flutterwave',
      'please_agree_terms': 'Please agree to terms and conditions',
      'fetching_rate': 'Fetching exchange rate, please wait…',
      'payment_not_configured': 'Payment not configured. Please contact support.',
      'payment_cancelled': 'Payment cancelled',
      'payment_successful': 'Payment successful! Funds are now held in escrow.',
      'payment_error': 'Payment error. Please try again.',
      'transaction_details': 'Transaction Details',
      'transaction_information': 'Transaction Information',
      'transaction_id': 'Transaction ID',
      'buyer_label': 'Buyer',
      'amount_label': 'Amount',
      'payment_method': 'Payment Method',
      'created_label': 'Created',
      'retry_attempts': 'Retry Attempts',
      'status_timeline': 'Status Timeline',
      'dispute_raised': 'Dispute Raised',
      'action_completed': 'Action completed successfully',
      'transaction_not_found': 'Transaction not found',
      'pending_payment': 'Pending Payment',
      'funds_held_escrow': 'Funds Held in Escrow',
      'awaiting_buyer_confirmation': 'Awaiting Buyer Confirmation',
      'disputed': 'Disputed',
      'confirm_delivery_title': 'Confirm Delivery',
      'confirm_delivery_message':
          'Have you delivered the coffee to the buyer? This action cannot be undone.',
      'confirm_receipt_title': 'Confirm Receipt',
      'confirm_receipt_message':
          'Have you received the coffee in good condition? Funds will be released to the farmer.',
      'confirm_release_funds': 'Confirm & Release Funds',
      'raise_dispute': 'Raise Dispute',
      'dispute_reason': 'Dispute Reason',
      'describe_issue': 'Describe the issue...',
      'dispute_description': 'Please describe the issue with this transaction:',
      'submit_dispute': 'Submit Dispute',
      'my_orders': 'My Orders',
      'orders_subtitle': 'Track your coffee purchases and supply chain status.',
      'no_transactions_title': 'No Transactions Yet',
      'no_transactions_description':
          'Your coffee orders and payments will appear here.',
      'view_all': 'View all',
      'live_trace_active': 'LIVE TRACE: ACTIVE',
      'awaiting_payment_title': 'Awaiting Payment',
      'in_transit': 'In Transit',
      'delivered': 'Delivered',
      'origin': 'Origin',
      'processing_step': 'Processing',
      'export': 'Export',
      'freight': 'Freight',
      'delivery': 'Delivery',
      // profile
      'profile_title': 'Profile',
      'email_verified': 'Email Verified',
      'email_unverified': 'Email Unverified',
      'verify_email': 'Verify Email',
      'farm_details_label': 'Farm Details',
      'business_details_label': 'Business Details',
      'farm_size': 'Farm Size',
      'location': 'Location',
      'coffee_varieties_label': 'Coffee Varieties',
      'registration_no': 'Registration No.',
      'monthly_volume': 'Monthly Volume',
      'not_set': 'Not set',
      'edit_profile': 'Edit Profile',
      'loading_profile': 'Loading profile...',
      'no_profile_found': 'No profile found.',
      // settings
      'using_dark_theme': 'Using dark theme',
      'using_light_theme': 'Using light theme',
      'new_listings': 'New Listings',
      'payments_label': 'Payments',
      'market_price_alerts': 'Market & Price Alerts',
      'preferences_saved_info':
          'Preferences are saved locally and persist across app restarts.',
      'messages_subtitle': 'New messages from buyers or farmers',
      'new_listings_subtitle': 'Alerts when new coffee lots are posted',
      'payments_subtitle': 'Transaction status & dispute alerts',
      'market_alerts_subtitle': 'Coffee price movements and market updates',
      // saved lots
      'saved_lots_title': 'Saved Lots',
      'clear_all': 'Clear All',
      'no_saved_lots': 'No saved lots yet',
      'no_saved_lots_hint':
          'Tap the heart on any listing in the Shop to save it here.',
      'price_per_kg_label': 'Price / KG',
      'kg_available': 'kg available',
      'message_button': 'Message',
      'direct_pay': 'Direct Pay',
      // search
      'direct_trade_shop': 'Direct Trade\nShop',
      'shop_subtitle': 'Explore specialty lots directly from their producers.',
      'search_hint': 'Search varieties, origins, or producers',
      'hide_filters': 'HIDE FILTERS',
      'advanced_filters': 'ADVANCED FILTERS',
      'origin_country': 'ORIGIN COUNTRY',
      'processing_method': 'PROCESSING METHOD',
      'price_range_usd': 'PRICE RANGE (USD/KG)',
      'altitude_range': 'ALTITUDE RANGE (m)',
      'min': 'Min',
      'max': 'Max',
      'clear': 'CLEAR',
      'apply_filters': 'APPLY FILTERS',
      'no_listings_found': 'No listings found',
      'try_adjusting_filters': 'Try adjusting your filters',
      'no_map_data': 'No map data',
      'no_map_coordinates': 'Listings do not have coordinates yet',
      'list_view': 'List view',
      'map_view': 'Map view',
      'removed_from_saved': 'removed from saved lots',
      'saved_to_wishlist': 'saved to your wishlist',
      'view': 'View',
      'lot_rating': 'Lot rating',
      'producer': 'Producer',
      // voice
      'chief_curator': 'Chief Curator',
      'voice_greeting':
          'Greetings, Clarisse. Elias is ready to consult on brewing chemistry, origin ethics, or your current supply chain waypoints',
      'initialize_session': 'INITIALIZE SESSION',
      'end_session': 'END SESSION',
      'chief_curator_active': 'Chief Curator — Active',
      'try_again': 'Try Again',
      // edit profile
      'edit_profile_title': 'Edit Profile',
      'display_name': 'Display Name',
      'display_name_hint': 'Enter your display name',
      'display_name_required': 'Display name is required',
      'discard_changes_title': 'Discard changes?',
      'discard_changes_message':
          'You have unsaved changes. Are you sure you want to discard them?',
      'discard': 'Discard',
      'save_changes': 'Save Changes',
      'photo_upload_failed': 'Photo upload failed. Please try again.',
    },
    'rw': {
      // Kinyarwanda
      'app_name': 'BrewMaster',
      'login': 'Injira',
      'sign_up': 'Iyandikishe',
      'email': 'Imeyili',
      'password': 'Ijambo ryibanga',
      'dashboard': 'Imbonerahamwe',
      'search': 'Shakisha',
      'messages': 'Ubutumwa',
      'profile': 'Umwirondoro',
      'listings': 'Urutonde',
      'market_prices': "Ibiciro by'isoko",
      'sign_out': 'Sohoka',
      'error_network': 'Nta savisi ya internet. Reba umuyoboro wawe.',
      'error_server': 'Ikosa rya seriveri. Gerageza nyuma.',
      'error_auth': 'Kwinjira ntibyakunze. Injira nanone.',
      'error_unknown': 'Hari ikosa ritaretse.',
      'error_permission': 'Ntufite uburenganzira.',
      'retry': 'Gerageza nanone',
      'cancel': 'Reka',
      'save': 'Bika',
      'delete': 'Siba',
      'confirm': 'Emeza',
      'voice_input_hint': 'Kanda micro uvuge',
      'voice_listening': 'Kumva...',
      'voice_not_available': 'Injiza ijwi ntiboneka',
      'verified': 'Byemejwe',
      'pending': 'Birimo gutegerezwa',
      'rejected': 'Byanzwe',
      'get_verified': 'Emezwa',
      'shop': 'Isoko',
      'orders': 'Amazamuriro',
      'prices': 'Ibiciro',
      'my_store': 'Iduka ryanjye',
      'settings': 'Igenamiterere',
      'language': 'Ururimi',
      'appearance': 'Isura',
      'notifications': 'Amatangazo',
      'dark_mode': 'Uburyo bwumwijima',
      // auth
      'welcome_back': 'Murakaza neza',
      'login_subtitle': 'Injira muri konti yawe ya BrewMaster.',
      'email_address': 'Aderesi ya Imeyili',
      'email_required': 'Imeyili irakenewe',
      'email_invalid': 'Injiza imeyili nzima',
      'password_required': 'Ijambo ryibanga rirakenewe',
      'sign_in_as_buyer': 'Injira nka Mushoromyi',
      'sign_in_as_seller': 'Injira nka Mugurisha',
      'forgot_password': 'Wibagiwe ijambo ryibanga?',
      'password_reset_sent': 'Ubutumwa bwo gusubiza ijambo ryibanga bwoherejwe.',
      'please_enter_email_first': 'Nyamuneka injiza imeyili yawe mbere.',
      'or': 'CYANGWA',
      'sign_in_with_google': 'Injira na Google',
      'no_account': "Nufite konti? ",
      'create_one': 'Fungura konti',
      'join_brewmaster': 'Injira muri BrewMaster',
      'signup_subtitle': 'Hitamo uruhare rwawe utangire urugendo.',
      'full_name': 'Amazina yuzuye',
      'name_required': 'Izina rirakenewe',
      'confirm_password': 'Emeza Ijambo ryibanga',
      'please_confirm_password': 'Nyamuneka emeza ijambo ryibanga',
      'passwords_do_not_match': 'Amagambo yibanga ntahuye',
      'sign_up_as_buyer': 'Iyandikishe nka Mushoromyi',
      'sign_up_as_seller': 'Iyandikishe nka Mugurisha',
      'sign_up_with_google': 'Iyandikishe na Google',
      'already_have_account': 'Usanzwe ufite konti? ',
      'sign_in': 'Injira',
      'i_want_to_buy': 'Ndashaka kugura',
      'i_want_to_sell': 'Ndashaka kugurisha',
      'buyer': 'Mushoromyi',
      'seller': 'Mugurisha',
      'farmer': 'Umuhinzi',
      // profile setup
      'complete_your_profile': 'Uzuza Umwirondoro Wawe',
      'select_your_role': 'Hitamo Uruhare Rwawe',
      'what_is_your_role': 'Uruhare rwawe ni irihe?',
      'role_help_text': 'Ibi bitugira ingirakamaro kugaragaza ibikureshaho.',
      'im_a_farmer': 'Ndi Umuhinzi',
      'grow_sell_coffee': 'Hindura uzagurisha ibinyobwa',
      'im_a_buyer': 'Ndi Mushoromyi',
      'purchase_trade_coffee': 'Gura ukore ubucuruzi bwa kawa',
      'farm_details': 'Amakuru ya Ubutaka',
      'business_details': 'Amakuru ya Ubucuruzi',
      'tell_us_about_farm': 'Tubwire birenzeho ubutaka bwawe.',
      'tell_us_about_business': 'Tubwire birenzeho ubucuruzi bwawe.',
      'country': 'Igihugu',
      'select_country': 'Hitamo igihugu cyawe',
      'farm_size_hectares': 'Ubugari bwa Ubutaka (hekitari)',
      'farm_location': 'Aho Ubutaka Buherereye',
      'coffee_varieties': 'Ubwoko bwa Kawa',
      'coffee_varieties_hint': 'urugero: Arabica, Robusta',
      'separate_with_commas': 'Erekana ubwoko ukoresha akabonyabugenge',
      'farm_registration_number': 'Nomero yo Kwandikisha Ubutaka',
      'optional': 'Bitegetswe',
      'business_name': 'Izina ry\'Ubucuruzi',
      'business_name_hint': 'Injiza izina ry\'ubucuruzi bwawe',
      'business_type': 'Ubwoko bw\'Ubucuruzi',
      'business_type_hint': 'urugero: Usarabusha, Ohereza, Ugurisha',
      'monthly_volume_kg': 'Ingano ya buri kwezi (kg)',
      'save_profile': 'Bika Umwirondoro',
      'please_select_role': 'Nyamuneka hitamo uruhare (Umuhinzi cyangwa Mushoromyi)',
      'enter_valid_farm_size': 'Injiza ubugari nzima bwa ubutaka',
      'enter_valid_volume': 'Injiza ingano nzima',
      // dashboard
      'farmer_command': 'Amabwiriza\ny\'Umuhinzi',
      'active_seller': 'Mugurisha Akora | Umuyoboro: Urinzwe',
      'analytics': 'ISESENGURA',
      'active_lots': 'IBICE BIKORA',
      'orders_logged': 'IBISABWA BYANDITSWE',
      'total_revenue': 'INYUNGU YOSE',
      'velocity_command': 'INSHINGANO YA VELO',
      'seven_day_revenue': 'Inyungu y\'iminsi 7',
      'market_intelligence': 'UBWENGE BW\'ISOKO',
      'saved': 'Byabitswe',
      'response_rate': 'Igipimo cy\'igisubizo',
      'no_orders_yet': 'Nta bisabwa kugeza ubu.',
      'confirm_delivery': 'Emeza Gutanga',
      'delivery_confirmed': 'Gutanga byemejwe neza.',
      'awaiting_payment': 'Gutegereza ubwishyu',
      'in_escrow': 'Mu bubiko',
      'delivered_awaiting_confirmation': 'Gutanzwe — gutegereza kwemezwa',
      'completed': 'Byarangiye',
      'under_dispute': 'Munsi y\'impaka',
      'cancelled': 'Byahagaritswe',
      'initialize_lot': '+ TANGIRA IGICE',
      'no_listings_yet':
          'Nta rutonde kugeza ubu. Kanda buto hejuru kugirango usangire igice cya mbere.',
      'my_dashboard': 'Imbonerahamwe\nyanjye',
      'buyer_dashboard_subtitle':
          'Ibikorwa byawe byo kugura kawa bizibika mu buryo bworoshye.',
      'total_purchases': 'IBIGURISHWA BYOSE',
      'conversations': 'IBIBAZO',
      'saved_lots': 'IBICE BYABITSWE',
      'quick_access': 'GERA VUBA',
      'browse_shop': 'Shakisha\nIsoko',
      'market_prices_label': 'Ibiciro\nbya Isoko',
      'loading_dashboard': 'Gutara imbonerahamwe yawe…',
      'refresh': 'Vugurura',
      // market prices
      'live_commodity_index': 'IGIPIMO CY\'ISOKO MU GIHE NYACYO',
      'no_market_prices': 'Nta biciro bya isoko bihari.',
      'loading_market_prices': 'Gutara ibiciro bya isoko…',
      'sync_prices': 'Huza ibiciro',
      'low': 'Hasi',
      'average': 'Hagati',
      'high': 'Hejuru',
      'updated': 'Ivuguruwe',
      // listings
      'coffee_profile': 'UMWIRONDORO WA KAWA',
      'processing_station': 'AHANTU HO GUCUKURA',
      'specifications': 'IBISOBANURO',
      'altitude': 'Uburebure',
      'processing': 'Gucukura',
      'harvest_year': 'Umwaka w\'Isarura',
      'quality_score': 'Amanota y\'Ubwiza',
      'available': 'Ibiriho',
      'price_per_kg': 'Igiciro / kg',
      'farm_location_label': 'AHO UBUTAKA BUHEREREYE',
      'contact_farmer': 'VUGANA N\'UMUHINZI',
      'this_is_your_listing': 'Iri ni urutonde rwawe.',
      'create_listing': 'Fungura Urutonde',
      'edit_listing': 'Hindura Urutonde',
      'update_listing': 'Vugurura Urutonde',
      'variety': 'Ubwoko',
      'quantity_kg': 'Ingano (kg)',
      'price_per_kg_usd': 'Igiciro cya kg (USD)',
      'altitude_m': 'Uburebure (m)',
      'harvest_date': 'Itariki y\'Isarura',
      'quality_score_0_100': 'Amanota y\'Ubwiza (0-100)',
      'description': 'Ibisobanuro',
      'describe_your_coffee': 'Sobanura kawa yawe',
      'farm_location_address': 'Aderesi y\'Aho Ubutaka Buherereye *',
      'latitude': 'Agero y\'Amajyaruguru',
      'longitude': 'Agero y\'Iburengerazuba',
      'auto_filled': 'Yuzuzwa Vuba',
      'geocode_tooltip': 'Hindura aderesi mu nshundura',
      'pick_images': 'Hitamo Amashusho',
      'images_selected': 'amashusho yatoranijwe',
      'fill_required_fields':
          'Nyamuneka uzuza imirima yose ikenewe harimo na aderesi',
      'geocode_failed': 'Ntibyakunze kubona inshundura zayo aderesi.',
      // messaging
      'direct_messaging': 'UBUTUMWA BUTAZIGUYE',
      'search_conversations': 'Shakisha ibibazo...',
      'no_messages_title': 'Nta Butumwa',
      'no_messages_description':
          'Tangira ikiganiro kugirango uvugane n\'abahinzi cyangwa abashoromyi',
      'no_messages_yet': 'Nta butumwa kugeza ubu',
      'say_hi':
          'Baza! Baza ku bwoko bwa kawa,\nuko bungwa, cyangwa guteganya kohereza.',
      'stop_listening': 'Hagarika kumva',
      'speak': 'Vuga',
      'type_a_message': 'Andika ubutumwa...',
      'speech_not_available': 'Gutegura amajwi ntiboneka kuri iyi cuma.',
      'conversation': 'Ikiganiro',
      // notifications
      'no_notifications_title': 'Nta matangazo',
      'no_notifications_description': "Warangije byose!",
      'mark_all_read': 'Shyira byose nk\'ibyasomwe',
      // payments
      'make_payment': 'Tanga Ubwishyu',
      'payment_summary': 'Incamake y\'Ubwishyu',
      'amount_usd': 'Amafaranga (USD):',
      'transaction_fee': 'Amafaranga y\'Ubwishyu:',
      'total_usd': 'Yose (USD):',
      'powered_by_flutterwave':
          'Ikoreshwa na Flutterwave. Hitamo uburyo bwawe bwiza (ikarita, amafaranga kuri telefoni, MPESA) ku ipaji ikurikira.',
      'agree_terms': 'Nemeye amabwiriza n\'ibisabwa bya escrow',
      'escrow_info':
          'Ubwishyu bwawe buzabikwa muri escrow kugeza ubwo gutanga kwemezwa n\'impande zombi.',
      'pay_with_flutterwave': 'Ishyura na Flutterwave',
      'please_agree_terms': 'Nyamuneka emera amabwiriza n\'ibisabwa',
      'fetching_rate': 'Gukurura ingano y\'ivunjisha, nyamuneka tegereza…',
      'payment_not_configured':
          'Ubwishyu ntugoranyijwe. Nyamuneka vugana n\'inkunga.',
      'payment_cancelled': 'Ubwishyu bwahagaritswe',
      'payment_successful': 'Ubwishyu bwagenze neza! Amafaranga agaragara muri escrow.',
      'payment_error': 'Ikosa ryo kwishyura. Gerageza nanone.',
      'transaction_details': 'Amakuru y\'Ubwishyu',
      'transaction_information': 'Amakuru y\'Inyandiko',
      'transaction_id': 'Indangamuntu y\'Inyandiko',
      'buyer_label': 'Mushoromyi',
      'amount_label': 'Amafaranga',
      'payment_method': 'Uburyo bwo Kwishyura',
      'created_label': 'Byakozwe',
      'retry_attempts': 'Ibigeragezwa byo Kongera',
      'status_timeline': 'Inzira y\'Imimerere',
      'dispute_raised': 'Impaka Zagaragajwe',
      'action_completed': 'Igikorwa cyarangiye neza',
      'transaction_not_found': 'Inyandiko ntiboneka',
      'pending_payment': 'Gutegereza Ubwishyu',
      'funds_held_escrow': 'Amafaranga Afite muri Escrow',
      'awaiting_buyer_confirmation': 'Gutegereza Kwemezwa kwa Mushoromyi',
      'disputed': 'Hari Impaka',
      'confirm_delivery_title': 'Emeza Gutanga',
      'confirm_delivery_message':
          'Watanze kawa ku mushoromyi? Igikorwa niki gishobora guhindurwa.',
      'confirm_receipt_title': 'Emeza Kwakira',
      'confirm_receipt_message':
          'Wakiriye kawa mu buryo bwiza? Amafaranga azarekurirwa umuhinzi.',
      'confirm_release_funds': 'Emeza & Rekura Amafaranga',
      'raise_dispute': 'Vuga Impaka',
      'dispute_reason': 'Impamvu y\'Impaka',
      'describe_issue': 'Sobanura ikibazo...',
      'dispute_description': 'Nyamuneka sobanura ikibazo cy\'inyandiko iyi:',
      'submit_dispute': 'Ohereza Impaka',
      'my_orders': 'Ibisubizo Byanjye',
      'orders_subtitle':
          'Kurikira ibigurishwa byawe bya kawa n\'imimerere y\'umutororo w\'ibikoresho.',
      'no_transactions_title': 'Nta Nyandiko Kugeza Ubu',
      'no_transactions_description':
          'Amategeko yawe ya kawa n\'ubwishyu bizagaragara hano.',
      'view_all': 'Reba byose',
      'live_trace_active': 'GUKURIKIRANA MU GIHE NYACYO: BIRAKORA',
      'awaiting_payment_title': 'Gutegereza Ubwishyu',
      'in_transit': 'Uri mu nzira',
      'delivered': 'Bwatanzwe',
      'origin': 'Inkomoko',
      'processing_step': 'Gutunganya',
      'export': 'Kohereza Hanze',
      'freight': 'Gutwara',
      'delivery': 'Gutanga',
      // profile
      'profile_title': 'Umwirondoro',
      'email_verified': 'Imeyili Yemejwe',
      'email_unverified': 'Imeyili Ntiyemejwe',
      'verify_email': 'Emeza Imeyili',
      'farm_details_label': 'Amakuru ya Ubutaka',
      'business_details_label': 'Amakuru ya Ubucuruzi',
      'farm_size': 'Ubugari bwa Ubutaka',
      'location': 'Aho Aherereye',
      'coffee_varieties_label': 'Ubwoko bwa Kawa',
      'registration_no': 'Nomero yo Kwandikisha',
      'monthly_volume': 'Ingano ya buri kwezi',
      'not_set': 'Ntiyashyizweho',
      'edit_profile': 'Hindura Umwirondoro',
      'loading_profile': 'Gutara umwirondoro...',
      'no_profile_found': 'Nta mwirondoro ubonetse.',
      // settings
      'using_dark_theme': 'Ukoresha uburyo bwumwijima',
      'using_light_theme': 'Ukoresha uburyo bwumucyo',
      'new_listings': 'Urutonde Rushya',
      'payments_label': 'Ubwishyu',
      'market_price_alerts': 'Itangazo ry\'Isoko n\'Ibiciro',
      'preferences_saved_info':
          'Amahitamo yabitswe mu buryo bwa kuri uyu mugi kandi azigumye nyuma yo gutangira app.',
      'messages_subtitle': 'Ubutumwa bushya buturuka ku bashoromyi cyangwa abahinzi',
      'new_listings_subtitle': 'Amatangazo iyo ibice bishya bya kawa biboneka',
      'payments_subtitle': 'Imimerere y\'inyandiko n\'amatangazo y\'impaka',
      'market_alerts_subtitle': 'Impinduka z\'ibiciro bya kawa n\'amakuru ya isoko',
      // saved lots
      'saved_lots_title': 'Ibice Byabitswe',
      'clear_all': 'Siba Byose',
      'no_saved_lots': 'Nta bice byabitswe kugeza ubu',
      'no_saved_lots_hint':
          'Kanda umutima ku rutonde rwarwo mu Isoko kugirango urubike hano.',
      'price_per_kg_label': 'Igiciro / KG',
      'kg_available': 'kg ibiri',
      'message_button': 'Ubutumwa',
      'direct_pay': 'Ishyura Vuba',
      // search
      'direct_trade_shop': 'Isoko\nRyaziguye',
      'shop_subtitle': 'Shakisha ibice bya specialite bivuye ku bahinzi.',
      'search_hint': 'Shakisha ubwoko, inkomoko, cyangwa abahinzi',
      'hide_filters': 'HISHA INZITIZI',
      'advanced_filters': 'INZITIZI NZINZWE',
      'origin_country': 'IGIHUGU CY\'INKOMOKO',
      'processing_method': 'UBURYO BWO GUTUNGANYA',
      'price_range_usd': 'INTERA Y\'IGICIRO (USD/KG)',
      'altitude_range': 'INTERA Y\'UBUREBURE (m)',
      'min': 'Ntarengwa',
      'max': 'Ntarengwa Cyane',
      'clear': 'SIBA',
      'apply_filters': 'SHYIRA INZITIZI',
      'no_listings_found': 'Nta rutonde rubonetse',
      'try_adjusting_filters': 'Gerageza guhindura inzitizi',
      'no_map_data': 'Nta makuru ya karti',
      'no_map_coordinates': 'Urutonde rufite inshundura kugeza ubu',
      'list_view': 'Reba nk\'urutonde',
      'map_view': 'Reba karti',
      'removed_from_saved': 'yasibwe mu bice byabitswe',
      'saved_to_wishlist': 'yabitswe mu rutonde rwawe',
      'view': 'Reba',
      'lot_rating': 'Amanota y\'igice',
      'producer': 'Umusarabusha',
      // voice
      'chief_curator': 'Umuyobozi Mukuru',
      'voice_greeting':
          'Murakaza neza, Clarisse. Elias arategurwa kuganira ku kimia cyo guteka, inyungu z\'inkomoko, cyangwa inzira z\'ibikoresho byawe',
      'initialize_session': 'TANGIRA IKIGANIRO',
      'end_session': 'RANGIZA IKIGANIRO',
      'chief_curator_active': 'Umuyobozi Mukuru — Akora',
      'try_again': 'Gerageza Nanone',
      // edit profile
      'edit_profile_title': 'Hindura Umwirondoro',
      'display_name': 'Izina Rigaragara',
      'display_name_hint': 'Injiza izina rigaragara',
      'display_name_required': 'Izina rigaragara rirakenewe',
      'discard_changes_title': 'Higa impinduka?',
      'discard_changes_message':
          'Ufite impinduka zitabitswe. Urashaka kuzihiga?',
      'discard': 'Higa',
      'save_changes': 'Bika Impinduka',
      'photo_upload_failed': 'Kohereza ifoto byanze. Gerageza nanone.',
    },
    'sw': {
      // Swahili
      'app_name': 'BrewMaster',
      'login': 'Ingia',
      'sign_up': 'Jisajili',
      'email': 'Barua pepe',
      'password': 'Nenosiri',
      'dashboard': 'Dashibodi',
      'search': 'Tafuta',
      'messages': 'Ujumbe',
      'profile': 'Wasifu',
      'listings': 'Orodha',
      'market_prices': 'Bei za soko',
      'sign_out': 'Toka',
      'error_network': 'Hakuna mtandao. Tafadhali angalia muunganiko wako.',
      'error_server': 'Hitilafu ya seva. Jaribu tena baadaye.',
      'error_auth': 'Uthibitishaji umeshindwa. Tafadhali ingia tena.',
      'error_unknown': 'Hitilafu isiyotarajiwa imetokea.',
      'error_permission': 'Ruhusa imekataliwa.',
      'retry': 'Jaribu tena',
      'cancel': 'Ghairi',
      'save': 'Hifadhi',
      'delete': 'Futa',
      'confirm': 'Thibitisha',
      'voice_input_hint': 'Gonga maikrofoni kuongea',
      'voice_listening': 'Inasikiliza...',
      'voice_not_available': 'Ingizo la sauti halipatikani',
      'verified': 'Imethibitishwa',
      'pending': 'Inasubiri',
      'rejected': 'Imekataliwa',
      'get_verified': 'Thibitisha',
      'shop': 'Duka',
      'orders': 'Maagizo',
      'prices': 'Bei',
      'my_store': 'Duka langu',
      'settings': 'Mipangilio',
      'language': 'Lugha',
      'appearance': 'Muonekano',
      'notifications': 'Arifa',
      'dark_mode': 'Hali ya giza',
      // auth
      'welcome_back': 'Karibu Tena',
      'login_subtitle': 'Ingia kwenye akaunti yako ya BrewMaster.',
      'email_address': 'Anwani ya Barua Pepe',
      'email_required': 'Barua pepe inahitajika',
      'email_invalid': 'Weka barua pepe halali',
      'password_required': 'Nenosiri linahitajika',
      'sign_in_as_buyer': 'Ingia kama Mnunuzi',
      'sign_in_as_seller': 'Ingia kama Muuzaji',
      'forgot_password': 'Umesahau nenosiri?',
      'password_reset_sent': 'Barua pepe ya kubadilisha nenosiri imetumwa.',
      'please_enter_email_first': 'Tafadhali weka barua pepe yako kwanza.',
      'or': 'AU',
      'sign_in_with_google': 'Ingia na Google',
      'no_account': "Huna akaunti? ",
      'create_one': 'Fungua moja',
      'join_brewmaster': 'Jiunge na BrewMaster',
      'signup_subtitle': 'Chagua jukumu lako na uanze safari yako.',
      'full_name': 'Jina kamili',
      'name_required': 'Jina linahitajika',
      'confirm_password': 'Thibitisha Nenosiri',
      'please_confirm_password': 'Tafadhali thibitisha nenosiri lako',
      'passwords_do_not_match': 'Manenosiri hayalingani',
      'sign_up_as_buyer': 'Jisajili kama Mnunuzi',
      'sign_up_as_seller': 'Jisajili kama Muuzaji',
      'sign_up_with_google': 'Jisajili na Google',
      'already_have_account': 'Una akaunti tayari? ',
      'sign_in': 'Ingia',
      'i_want_to_buy': 'Nataka kununua',
      'i_want_to_sell': 'Nataka kuuza',
      'buyer': 'Mnunuzi',
      'seller': 'Muuzaji',
      'farmer': 'Mkulima',
      // profile setup
      'complete_your_profile': 'Kamilisha Wasifu Wako',
      'select_your_role': 'Chagua Jukumu Lako',
      'what_is_your_role': 'Jukumu lako ni nini?',
      'role_help_text':
          'Hii inatusaidia kukuonyesha vipengele na maudhui yanayofaa.',
      'im_a_farmer': 'Mimi ni Mkulima',
      'grow_sell_coffee': 'Kilimo na kuuza kahawa',
      'im_a_buyer': 'Mimi ni Mnunuzi',
      'purchase_trade_coffee': 'Nunua na biashara ya kahawa',
      'farm_details': 'Maelezo ya Shamba',
      'business_details': 'Maelezo ya Biashara',
      'tell_us_about_farm': 'Tuambie zaidi kuhusu shamba lako.',
      'tell_us_about_business': 'Tuambie zaidi kuhusu biashara yako.',
      'country': 'Nchi',
      'select_country': 'Chagua nchi yako',
      'farm_size_hectares': 'Ukubwa wa Shamba (hekta)',
      'farm_location': 'Mahali pa Shamba',
      'coffee_varieties': 'Aina za Kahawa',
      'coffee_varieties_hint': 'mfano: Arabica, Robusta',
      'separate_with_commas': 'Tenganisha aina kwa mkato',
      'farm_registration_number': 'Nambari ya Usajili wa Shamba',
      'optional': 'Si lazima',
      'business_name': 'Jina la Biashara',
      'business_name_hint': 'Weka jina la biashara yako',
      'business_type': 'Aina ya Biashara',
      'business_type_hint': 'mfano: Mkaawaaji, Msafirishaji, Muuzaji Rejareja',
      'monthly_volume_kg': 'Kiasi cha Kila Mwezi (kg)',
      'save_profile': 'Hifadhi Wasifu',
      'please_select_role': 'Tafadhali chagua jukumu (Mkulima au Mnunuzi)',
      'enter_valid_farm_size': 'Weka ukubwa halali wa shamba',
      'enter_valid_volume': 'Weka kiasi halali',
      // dashboard
      'farmer_command': 'Amri ya\nMkulima',
      'active_seller': 'Muuzaji Anayefanya Kazi | Kiungo: Kimelindwa',
      'analytics': 'UCHAMBUZI',
      'active_lots': 'VIGAWE VINAVYOFANYA KAZI',
      'orders_logged': 'MAAGIZO YALIYOREKODIWA',
      'total_revenue': 'MAPATO YOTE',
      'velocity_command': 'AMRI YA KASI',
      'seven_day_revenue': 'Mapato ya siku 7',
      'market_intelligence': 'AKILI YA SOKO',
      'saved': 'Zilizohifadhiwa',
      'response_rate': 'Kiwango cha majibu',
      'no_orders_yet': 'Hakuna maagizo bado.',
      'confirm_delivery': 'Thibitisha Utoaji',
      'delivery_confirmed': 'Utoaji umethibitishwa kwa mafanikio.',
      'awaiting_payment': 'Inasubiri malipo',
      'in_escrow': 'Katika amana',
      'delivered_awaiting_confirmation': 'Imetolewa — inasubiri uthibitisho',
      'completed': 'Imekamilika',
      'under_dispute': 'Chini ya migogoro',
      'cancelled': 'Imeghairiwa',
      'initialize_lot': '+ ANZISHA KIGAWE',
      'no_listings_yet':
          'Hakuna orodha bado. Bonyeza kitufe hapo juu kuunda kigawe chako cha kwanza.',
      'my_dashboard': 'Dashibodi\nYangu',
      'buyer_dashboard_subtitle':
          'Shughuli zako za ununuzi wa kahawa kwa muhtasari.',
      'total_purchases': 'MANUNUZI YOTE',
      'conversations': 'MAZUNGUMZO',
      'saved_lots': 'VIGAWE VILIVYOHIFADHIWA',
      'quick_access': 'UFIKIAJI WA HARAKA',
      'browse_shop': 'Vinjari\nDuka',
      'market_prices_label': 'Bei za\nSoko',
      'loading_dashboard': 'Inapakia dashibodi yako…',
      'refresh': 'Onyesha upya',
      // market prices
      'live_commodity_index': 'FAHARASA YA BIDHAA YA MOJA KWA MOJA',
      'no_market_prices': 'Hakuna bei za soko zinazopatikana.',
      'loading_market_prices': 'Inapakia bei za soko…',
      'sync_prices': 'Sawazisha bei',
      'low': 'Chini',
      'average': 'Wastani',
      'high': 'Juu',
      'updated': 'Imesasishwa',
      // listings
      'coffee_profile': 'WASIFU WA KAHAWA',
      'processing_station': 'KITUO CHA USINDIKAJI',
      'specifications': 'MAELEZO',
      'altitude': 'Mwinuko',
      'processing': 'Usindikaji',
      'harvest_year': 'Mwaka wa Mavuno',
      'quality_score': 'Alama za Ubora',
      'available': 'Inapatikana',
      'price_per_kg': 'Bei / kg',
      'farm_location_label': 'MAHALI PA SHAMBA',
      'contact_farmer': 'WASILIANA NA MKULIMA',
      'this_is_your_listing': 'Hii ni orodha yako mwenyewe.',
      'create_listing': 'Unda Orodha',
      'edit_listing': 'Hariri Orodha',
      'update_listing': 'Sasisha Orodha',
      'variety': 'Aina',
      'quantity_kg': 'Kiasi (kg)',
      'price_per_kg_usd': 'Bei kwa kg (USD)',
      'altitude_m': 'Mwinuko (m)',
      'harvest_date': 'Tarehe ya Mavuno',
      'quality_score_0_100': 'Alama za Ubora (0-100)',
      'description': 'Maelezo',
      'describe_your_coffee': 'Elezea kahawa yako',
      'farm_location_address': 'Anwani ya Mahali pa Shamba *',
      'latitude': 'Latitudi',
      'longitude': 'Longitudo',
      'auto_filled': 'Imejazwa Moja kwa Moja',
      'geocode_tooltip': 'Geuza anwani kuwa kuratibu',
      'pick_images': 'Chagua Picha',
      'images_selected': 'picha zilizochaguliwa',
      'fill_required_fields':
          'Tafadhali jaza sehemu zote zinazohitajika ikiwemo anwani',
      'geocode_failed': 'Haikuweza kupata kuratibu kwa anwani hiyo.',
      // messaging
      'direct_messaging': 'UJUMBE WA MOJA KWA MOJA',
      'search_conversations': 'Tafuta mazungumzo...',
      'no_messages_title': 'Hakuna Ujumbe',
      'no_messages_description':
          'Anza mazungumzo kuungana na wakulima au wanunuzi',
      'no_messages_yet': 'Hakuna ujumbe bado',
      'say_hi':
          'Sema habari! Uliza kuhusu aina ya kahawa,\nnjia ya usindikaji, au panga usafirishaji.',
      'stop_listening': 'Simama kusikiliza',
      'speak': 'Sema',
      'type_a_message': 'Andika ujumbe...',
      'speech_not_available':
          'Utambuzi wa hotuba haupatikani kwenye kifaa hiki.',
      'conversation': 'Mazungumzo',
      // notifications
      'no_notifications_title': 'Hakuna arifa',
      'no_notifications_description': "Umekwisha kusoma kila kitu!",
      'mark_all_read': 'Weka zote kama zilizosomwa',
      // payments
      'make_payment': 'Fanya Malipo',
      'payment_summary': 'Muhtasari wa Malipo',
      'amount_usd': 'Kiasi (USD):',
      'transaction_fee': 'Ada ya Muamala:',
      'total_usd': 'Jumla (USD):',
      'powered_by_flutterwave':
          'Inafanywa na Flutterwave. Chagua njia yako inayopendwa (kadi, pesa ya simu, MPESA) kwenye skrini inayofuata.',
      'agree_terms': 'Nakubali masharti na hali za malipo ya amana',
      'escrow_info':
          'Malipo yako yatashikiliwa katika amana hadi utoaji uthibitishwe na pande zote mbili.',
      'pay_with_flutterwave': 'Lipa na Flutterwave',
      'please_agree_terms': 'Tafadhali kubali masharti na hali',
      'fetching_rate': 'Inapata kiwango cha ubadilishaji, tafadhali subiri…',
      'payment_not_configured':
          'Malipo hayajasanidiwa. Tafadhali wasiliana na msaada.',
      'payment_cancelled': 'Malipo yameghairiwa',
      'payment_successful':
          'Malipo yamefanikiwa! Fedha sasa zimeshikiliwa katika amana.',
      'payment_error': 'Hitilafu ya malipo. Tafadhali jaribu tena.',
      'transaction_details': 'Maelezo ya Muamala',
      'transaction_information': 'Taarifa ya Muamala',
      'transaction_id': 'Kitambulisho cha Muamala',
      'buyer_label': 'Mnunuzi',
      'amount_label': 'Kiasi',
      'payment_method': 'Njia ya Malipo',
      'created_label': 'Iliundwa',
      'retry_attempts': 'Majaribio ya Kurudia',
      'status_timeline': 'Kalenda ya Hali',
      'dispute_raised': 'Mgogoro Umetolewa',
      'action_completed': 'Hatua imekamilika kwa mafanikio',
      'transaction_not_found': 'Muamala haukupatikana',
      'pending_payment': 'Malipo Yanayosubiri',
      'funds_held_escrow': 'Fedha Zimeshikiliwa katika Amana',
      'awaiting_buyer_confirmation': 'Inasubiri Uthibitisho wa Mnunuzi',
      'disputed': 'Ina Mgogoro',
      'confirm_delivery_title': 'Thibitisha Utoaji',
      'confirm_delivery_message':
          'Je, umetoa kahawa kwa mnunuzi? Hatua hii haiwezi kutendwa upya.',
      'confirm_receipt_title': 'Thibitisha Kupokea',
      'confirm_receipt_message':
          'Je, umepokea kahawa katika hali nzuri? Fedha zitatolewa kwa mkulima.',
      'confirm_release_funds': 'Thibitisha & Toa Fedha',
      'raise_dispute': 'Toa Mgogoro',
      'dispute_reason': 'Sababu ya Mgogoro',
      'describe_issue': 'Elezea tatizo...',
      'dispute_description': 'Tafadhali elezea tatizo la muamala huu:',
      'submit_dispute': 'Wasilisha Mgogoro',
      'my_orders': 'Maagizo Yangu',
      'orders_subtitle':
          'Fuatilia manunuzi yako ya kahawa na hali ya mnyororo wa usambazaji.',
      'no_transactions_title': 'Hakuna Miamala Bado',
      'no_transactions_description':
          'Maagizo yako ya kahawa na malipo yataonekana hapa.',
      'view_all': 'Ona yote',
      'live_trace_active': 'UFUATILIAJI WA MOJA KWA MOJA: INAFANYA KAZI',
      'awaiting_payment_title': 'Inasubiri Malipo',
      'in_transit': 'Safarini',
      'delivered': 'Imetolewa',
      'origin': 'Asili',
      'processing_step': 'Usindikaji',
      'export': 'Usafirishaji',
      'freight': 'Mzigo',
      'delivery': 'Utoaji',
      // profile
      'profile_title': 'Wasifu',
      'email_verified': 'Barua Pepe Imethibitishwa',
      'email_unverified': 'Barua Pepe Haijathibitishwa',
      'verify_email': 'Thibitisha Barua Pepe',
      'farm_details_label': 'Maelezo ya Shamba',
      'business_details_label': 'Maelezo ya Biashara',
      'farm_size': 'Ukubwa wa Shamba',
      'location': 'Mahali',
      'coffee_varieties_label': 'Aina za Kahawa',
      'registration_no': 'Nambari ya Usajili',
      'monthly_volume': 'Kiasi cha Kila Mwezi',
      'not_set': 'Haijawekwa',
      'edit_profile': 'Hariri Wasifu',
      'loading_profile': 'Inapakia wasifu...',
      'no_profile_found': 'Hakuna wasifu uliopatikana.',
      // settings
      'using_dark_theme': 'Inatumia mandhari nyeusi',
      'using_light_theme': 'Inatumia mandhari nyeupe',
      'new_listings': 'Orodha Mpya',
      'payments_label': 'Malipo',
      'market_price_alerts': 'Arifa za Soko na Bei',
      'preferences_saved_info':
          'Mapendeleo yamehifadhiwa hapa ndipo na yanabaki baada ya kuanzisha upya programu.',
      'messages_subtitle': 'Ujumbe mpya kutoka kwa wanunuzi au wakulima',
      'new_listings_subtitle': 'Arifa zinapoandikwa vigawe vipya vya kahawa',
      'payments_subtitle': 'Hali ya muamala na arifa za mgogoro',
      'market_alerts_subtitle':
          'Mabadiliko ya bei ya kahawa na masasisho ya soko',
      // saved lots
      'saved_lots_title': 'Vigawe Vilivyohifadhiwa',
      'clear_all': 'Futa Yote',
      'no_saved_lots': 'Hakuna vigawe vilivyohifadhiwa bado',
      'no_saved_lots_hint':
          'Gonga moyo kwenye orodha yoyote katika Duka ili kuihifadhi hapa.',
      'price_per_kg_label': 'Bei / KG',
      'kg_available': 'kg zinazopatikana',
      'message_button': 'Ujumbe',
      'direct_pay': 'Lipa Moja kwa Moja',
      // search
      'direct_trade_shop': 'Duka la\nBiashara Moja kwa Moja',
      'shop_subtitle': 'Chunguza vigawe maalum moja kwa moja kutoka kwa wazalishaji.',
      'search_hint': 'Tafuta aina, asili, au wazalishaji',
      'hide_filters': 'FICHA VICHUJIO',
      'advanced_filters': 'VICHUJIO VYA JUU',
      'origin_country': 'NCHI YA ASILI',
      'processing_method': 'NJIA YA USINDIKAJI',
      'price_range_usd': 'ANUWAI YA BEI (USD/KG)',
      'altitude_range': 'ANUWAI YA MWINUKO (m)',
      'min': 'Kiwango cha Chini',
      'max': 'Kiwango cha Juu',
      'clear': 'FUTA',
      'apply_filters': 'TUMIA VICHUJIO',
      'no_listings_found': 'Hakuna orodha zilizopatikana',
      'try_adjusting_filters': 'Jaribu kurekebisha vichujio',
      'no_map_data': 'Hakuna data ya ramani',
      'no_map_coordinates': 'Orodha hazina kuratibu bado',
      'list_view': 'Mwonekano wa orodha',
      'map_view': 'Mwonekano wa ramani',
      'removed_from_saved': 'imeondolewa kwenye vigawe vilivyohifadhiwa',
      'saved_to_wishlist': 'imehifadhiwa kwenye orodha yako',
      'view': 'Tazama',
      'lot_rating': 'Ukadiriaji wa kigawe',
      'producer': 'Mzalishaji',
      // voice
      'chief_curator': 'Msimamizi Mkuu',
      'voice_greeting':
          'Habari, Clarisse. Elias yuko tayari kushauriana kuhusu kemia ya kutengeneza kahawa, maadili ya asili, au pointi za mnyororo wako wa usambazaji',
      'initialize_session': 'ANZISHA KIKAO',
      'end_session': 'MALIZA KIKAO',
      'chief_curator_active': 'Msimamizi Mkuu — Anafanya Kazi',
      'try_again': 'Jaribu Tena',
      // edit profile
      'edit_profile_title': 'Hariri Wasifu',
      'display_name': 'Jina la Kuonyesha',
      'display_name_hint': 'Weka jina lako la kuonyesha',
      'display_name_required': 'Jina la kuonyesha linahitajika',
      'discard_changes_title': 'Tupa mabadiliko?',
      'discard_changes_message':
          'Una mabadiliko ambayo hayajahifadhiwa. Je, una uhakika unataka kuyatupa?',
      'discard': 'Tupa',
      'save_changes': 'Hifadhi Mabadiliko',
      'photo_upload_failed': 'Upakiaji wa picha umeshindwa. Tafadhali jaribu tena.',
    },
  };

  /// Looks up [key] in the current locale, falls back to English.
  String translate(String key) {
    final langCode = locale.languageCode;
    return _strings[langCode]?[key] ?? _strings['en']?[key] ?? key;
  }

  // ---------------------------------------------------------------------------
  // Convenience getters — common
  // ---------------------------------------------------------------------------

  String get appName => translate('app_name');
  String get login => translate('login');
  String get signUp => translate('sign_up');
  String get email => translate('email');
  String get password => translate('password');
  String get dashboard => translate('dashboard');
  String get search => translate('search');
  String get messages => translate('messages');
  String get profile => translate('profile');
  String get listings => translate('listings');
  String get marketPrices => translate('market_prices');
  String get signOut => translate('sign_out');
  String get errorNetwork => translate('error_network');
  String get errorServer => translate('error_server');
  String get errorAuth => translate('error_auth');
  String get errorUnknown => translate('error_unknown');
  String get errorPermission => translate('error_permission');
  String get retry => translate('retry');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get confirm => translate('confirm');
  String get voiceInputHint => translate('voice_input_hint');
  String get voiceListening => translate('voice_listening');
  String get voiceNotAvailable => translate('voice_not_available');
  String get verified => translate('verified');
  String get pending => translate('pending');
  String get rejected => translate('rejected');
  String get getVerified => translate('get_verified');
  String get shop => translate('shop');
  String get orders => translate('orders');
  String get prices => translate('prices');
  String get myStore => translate('my_store');
  String get settings => translate('settings');
  String get language => translate('language');
  String get appearance => translate('appearance');
  String get notificationsLabel => translate('notifications');
  String get darkMode => translate('dark_mode');

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  String get welcomeBack => translate('welcome_back');
  String get loginSubtitle => translate('login_subtitle');
  String get emailAddress => translate('email_address');
  String get emailRequired => translate('email_required');
  String get emailInvalid => translate('email_invalid');
  String get passwordRequired => translate('password_required');
  String get signInAsBuyer => translate('sign_in_as_buyer');
  String get signInAsSeller => translate('sign_in_as_seller');
  String get forgotPassword => translate('forgot_password');
  String get passwordResetSent => translate('password_reset_sent');
  String get pleaseEnterEmailFirst => translate('please_enter_email_first');
  String get or => translate('or');
  String get signInWithGoogle => translate('sign_in_with_google');
  String get noAccount => translate('no_account');
  String get createOne => translate('create_one');
  String get joinBrewmaster => translate('join_brewmaster');
  String get signupSubtitle => translate('signup_subtitle');
  String get fullName => translate('full_name');
  String get nameRequired => translate('name_required');
  String get confirmPassword => translate('confirm_password');
  String get pleaseConfirmPassword => translate('please_confirm_password');
  String get passwordsDoNotMatch => translate('passwords_do_not_match');
  String get signUpAsBuyer => translate('sign_up_as_buyer');
  String get signUpAsSeller => translate('sign_up_as_seller');
  String get signUpWithGoogle => translate('sign_up_with_google');
  String get alreadyHaveAccount => translate('already_have_account');
  String get signIn => translate('sign_in');
  String get iWantToBuy => translate('i_want_to_buy');
  String get iWantToSell => translate('i_want_to_sell');
  String get buyer => translate('buyer');
  String get seller => translate('seller');
  String get farmer => translate('farmer');

  // ---------------------------------------------------------------------------
  // Profile setup
  // ---------------------------------------------------------------------------
  String get completeYourProfile => translate('complete_your_profile');
  String get selectYourRole => translate('select_your_role');
  String get whatIsYourRole => translate('what_is_your_role');
  String get roleHelpText => translate('role_help_text');
  String get imAFarmer => translate('im_a_farmer');
  String get growSellCoffee => translate('grow_sell_coffee');
  String get imABuyer => translate('im_a_buyer');
  String get purchaseTradeCoffee => translate('purchase_trade_coffee');
  String get farmDetails => translate('farm_details');
  String get businessDetails => translate('business_details');
  String get tellUsAboutFarm => translate('tell_us_about_farm');
  String get tellUsAboutBusiness => translate('tell_us_about_business');
  String get country => translate('country');
  String get selectCountry => translate('select_country');
  String get farmSizeHectares => translate('farm_size_hectares');
  String get farmLocation => translate('farm_location');
  String get coffeeVarieties => translate('coffee_varieties');
  String get coffeeVarietiesHint => translate('coffee_varieties_hint');
  String get separateWithCommas => translate('separate_with_commas');
  String get farmRegistrationNumber => translate('farm_registration_number');
  String get optional => translate('optional');
  String get businessName => translate('business_name');
  String get businessNameHint => translate('business_name_hint');
  String get businessType => translate('business_type');
  String get businessTypeHint => translate('business_type_hint');
  String get monthlyVolumeKg => translate('monthly_volume_kg');
  String get saveProfile => translate('save_profile');
  String get pleaseSelectRole => translate('please_select_role');
  String get enterValidFarmSize => translate('enter_valid_farm_size');
  String get enterValidVolume => translate('enter_valid_volume');

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------
  String get farmerCommand => translate('farmer_command');
  String get activeSeller => translate('active_seller');
  String get analytics => translate('analytics');
  String get activeLots => translate('active_lots');
  String get ordersLogged => translate('orders_logged');
  String get totalRevenue => translate('total_revenue');
  String get velocityCommand => translate('velocity_command');
  String get sevenDayRevenue => translate('seven_day_revenue');
  String get marketIntelligence => translate('market_intelligence');
  String get savedLabel => translate('saved');
  String get responseRate => translate('response_rate');
  String get noOrdersYet => translate('no_orders_yet');
  String get confirmDelivery => translate('confirm_delivery');
  String get deliveryConfirmed => translate('delivery_confirmed');
  String get awaitingPayment => translate('awaiting_payment');
  String get inEscrow => translate('in_escrow');
  String get deliveredAwaitingConfirmation =>
      translate('delivered_awaiting_confirmation');
  String get completed => translate('completed');
  String get underDispute => translate('under_dispute');
  String get cancelled => translate('cancelled');
  String get initializeLot => translate('initialize_lot');
  String get noListingsYet => translate('no_listings_yet');
  String get myDashboard => translate('my_dashboard');
  String get buyerDashboardSubtitle => translate('buyer_dashboard_subtitle');
  String get totalPurchases => translate('total_purchases');
  String get conversationsLabel => translate('conversations');
  String get savedLotsLabel => translate('saved_lots');
  String get quickAccess => translate('quick_access');
  String get browseShop => translate('browse_shop');
  String get marketPricesLabel => translate('market_prices_label');
  String get loadingDashboard => translate('loading_dashboard');
  String get refresh => translate('refresh');

  // ---------------------------------------------------------------------------
  // Market prices
  // ---------------------------------------------------------------------------
  String get liveCommodityIndex => translate('live_commodity_index');
  String get noMarketPrices => translate('no_market_prices');
  String get loadingMarketPrices => translate('loading_market_prices');
  String get syncPrices => translate('sync_prices');
  String get low => translate('low');
  String get average => translate('average');
  String get high => translate('high');
  String get updated => translate('updated');

  // ---------------------------------------------------------------------------
  // Listings
  // ---------------------------------------------------------------------------
  String get coffeeProfile => translate('coffee_profile');
  String get processingStation => translate('processing_station');
  String get specifications => translate('specifications');
  String get altitude => translate('altitude');
  String get processing => translate('processing');
  String get harvestYear => translate('harvest_year');
  String get qualityScore => translate('quality_score');
  String get available => translate('available');
  String get pricePerKg => translate('price_per_kg');
  String get farmLocationLabel => translate('farm_location_label');
  String get contactFarmer => translate('contact_farmer');
  String get thisIsYourListing => translate('this_is_your_listing');
  String get createListing => translate('create_listing');
  String get editListing => translate('edit_listing');
  String get updateListing => translate('update_listing');
  String get variety => translate('variety');
  String get quantityKg => translate('quantity_kg');
  String get pricePerKgUsd => translate('price_per_kg_usd');
  String get altitudeM => translate('altitude_m');
  String get harvestDate => translate('harvest_date');
  String get qualityScore0100 => translate('quality_score_0_100');
  String get description => translate('description');
  String get describeYourCoffee => translate('describe_your_coffee');
  String get farmLocationAddress => translate('farm_location_address');
  String get latitude => translate('latitude');
  String get longitude => translate('longitude');
  String get autoFilled => translate('auto_filled');
  String get geocodeTooltip => translate('geocode_tooltip');
  String get pickImages => translate('pick_images');
  String get imagesSelected => translate('images_selected');
  String get fillRequiredFields => translate('fill_required_fields');
  String get geocodeFailed => translate('geocode_failed');

  // ---------------------------------------------------------------------------
  // Messaging
  // ---------------------------------------------------------------------------
  String get directMessaging => translate('direct_messaging');
  String get searchConversations => translate('search_conversations');
  String get noMessagesTitle => translate('no_messages_title');
  String get noMessagesDescription => translate('no_messages_description');
  String get noMessagesYet => translate('no_messages_yet');
  String get sayHi => translate('say_hi');
  String get stopListening => translate('stop_listening');
  String get speak => translate('speak');
  String get typeAMessage => translate('type_a_message');
  String get speechNotAvailable => translate('speech_not_available');
  String get conversation => translate('conversation');

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------
  String get noNotificationsTitle => translate('no_notifications_title');
  String get noNotificationsDescription =>
      translate('no_notifications_description');
  String get markAllRead => translate('mark_all_read');

  // ---------------------------------------------------------------------------
  // Payments
  // ---------------------------------------------------------------------------
  String get makePayment => translate('make_payment');
  String get paymentSummary => translate('payment_summary');
  String get amountUsd => translate('amount_usd');
  String get transactionFee => translate('transaction_fee');
  String get totalUsd => translate('total_usd');
  String get poweredByFlutterwave => translate('powered_by_flutterwave');
  String get agreeTerms => translate('agree_terms');
  String get escrowInfo => translate('escrow_info');
  String get payWithFlutterwave => translate('pay_with_flutterwave');
  String get pleaseAgreeTerms => translate('please_agree_terms');
  String get fetchingRate => translate('fetching_rate');
  String get paymentNotConfigured => translate('payment_not_configured');
  String get paymentCancelled => translate('payment_cancelled');
  String get paymentSuccessful => translate('payment_successful');
  String get paymentError => translate('payment_error');
  String get transactionDetails => translate('transaction_details');
  String get transactionInformation => translate('transaction_information');
  String get transactionId => translate('transaction_id');
  String get buyerLabel => translate('buyer_label');
  String get amountLabel => translate('amount_label');
  String get paymentMethod => translate('payment_method');
  String get createdLabel => translate('created_label');
  String get retryAttempts => translate('retry_attempts');
  String get statusTimeline => translate('status_timeline');
  String get disputeRaised => translate('dispute_raised');
  String get actionCompleted => translate('action_completed');
  String get transactionNotFound => translate('transaction_not_found');
  String get pendingPayment => translate('pending_payment');
  String get fundsHeldEscrow => translate('funds_held_escrow');
  String get awaitingBuyerConfirmation =>
      translate('awaiting_buyer_confirmation');
  String get disputed => translate('disputed');
  String get confirmDeliveryTitle => translate('confirm_delivery_title');
  String get confirmDeliveryMessage => translate('confirm_delivery_message');
  String get confirmReceiptTitle => translate('confirm_receipt_title');
  String get confirmReceiptMessage => translate('confirm_receipt_message');
  String get confirmReleaseFunds => translate('confirm_release_funds');
  String get raiseDispute => translate('raise_dispute');
  String get disputeReason => translate('dispute_reason');
  String get describeIssue => translate('describe_issue');
  String get disputeDescription => translate('dispute_description');
  String get submitDispute => translate('submit_dispute');
  String get myOrders => translate('my_orders');
  String get ordersSubtitle => translate('orders_subtitle');
  String get noTransactionsTitle => translate('no_transactions_title');
  String get noTransactionsDescription =>
      translate('no_transactions_description');
  String get viewAll => translate('view_all');
  String get liveTraceActive => translate('live_trace_active');
  String get awaitingPaymentTitle => translate('awaiting_payment_title');
  String get inTransit => translate('in_transit');
  String get delivered => translate('delivered');
  String get origin => translate('origin');
  String get processingStep => translate('processing_step');
  String get export => translate('export');
  String get freight => translate('freight');
  String get delivery => translate('delivery');

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------
  String get profileTitle => translate('profile_title');
  String get emailVerified => translate('email_verified');
  String get emailUnverified => translate('email_unverified');
  String get verifyEmail => translate('verify_email');
  String get farmDetailsLabel => translate('farm_details_label');
  String get businessDetailsLabel => translate('business_details_label');
  String get farmSize => translate('farm_size');
  String get location => translate('location');
  String get coffeeVarietiesLabel => translate('coffee_varieties_label');
  String get registrationNo => translate('registration_no');
  String get monthlyVolume => translate('monthly_volume');
  String get notSet => translate('not_set');
  String get editProfile => translate('edit_profile');
  String get loadingProfile => translate('loading_profile');
  String get noProfileFound => translate('no_profile_found');

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------
  String get usingDarkTheme => translate('using_dark_theme');
  String get usingLightTheme => translate('using_light_theme');
  String get newListings => translate('new_listings');
  String get paymentsLabel => translate('payments_label');
  String get marketPriceAlerts => translate('market_price_alerts');
  String get preferencesSavedInfo => translate('preferences_saved_info');
  String get messagesSubtitle => translate('messages_subtitle');
  String get newListingsSubtitle => translate('new_listings_subtitle');
  String get paymentsSubtitle => translate('payments_subtitle');
  String get marketAlertsSubtitle => translate('market_alerts_subtitle');

  // ---------------------------------------------------------------------------
  // Saved lots
  // ---------------------------------------------------------------------------
  String get savedLotsTitle => translate('saved_lots_title');
  String get clearAll => translate('clear_all');
  String get noSavedLots => translate('no_saved_lots');
  String get noSavedLotsHint => translate('no_saved_lots_hint');
  String get pricePerKgLabel => translate('price_per_kg_label');
  String get kgAvailable => translate('kg_available');
  String get messageButton => translate('message_button');
  String get directPay => translate('direct_pay');

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------
  String get directTradeShop => translate('direct_trade_shop');
  String get shopSubtitle => translate('shop_subtitle');
  String get searchHint => translate('search_hint');
  String get hideFilters => translate('hide_filters');
  String get advancedFilters => translate('advanced_filters');
  String get originCountry => translate('origin_country');
  String get processingMethod => translate('processing_method');
  String get priceRangeUsd => translate('price_range_usd');
  String get altitudeRange => translate('altitude_range');
  String get clear => translate('clear');
  String get applyFilters => translate('apply_filters');
  String get noListingsFound => translate('no_listings_found');
  String get tryAdjustingFilters => translate('try_adjusting_filters');
  String get noMapData => translate('no_map_data');
  String get noMapCoordinates => translate('no_map_coordinates');
  String get listView => translate('list_view');
  String get mapView => translate('map_view');
  String get removedFromSaved => translate('removed_from_saved');
  String get savedToWishlist => translate('saved_to_wishlist');
  String get view => translate('view');
  String get lotRating => translate('lot_rating');
  String get min => translate('min');
  String get max => translate('max');
  String get producer => translate('producer');

  // ---------------------------------------------------------------------------
  // Voice
  // ---------------------------------------------------------------------------
  String get chiefCurator => translate('chief_curator');
  String get voiceGreeting => translate('voice_greeting');
  String get initializeSession => translate('initialize_session');
  String get endSession => translate('end_session');
  String get chiefCuratorActive => translate('chief_curator_active');
  String get tryAgain => translate('try_again');

  // ---------------------------------------------------------------------------
  // Edit profile
  // ---------------------------------------------------------------------------
  String get editProfileTitle => translate('edit_profile_title');
  String get displayName => translate('display_name');
  String get displayNameHint => translate('display_name_hint');
  String get displayNameRequired => translate('display_name_required');
  String get discardChangesTitle => translate('discard_changes_title');
  String get discardChangesMessage => translate('discard_changes_message');
  String get discard => translate('discard');
  String get saveChanges => translate('save_changes');
  String get photoUploadFailed => translate('photo_upload_failed');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
