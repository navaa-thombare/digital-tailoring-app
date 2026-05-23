import 'dart:async';
import 'dart:ui';
import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'core/config/app_config.dart';
import 'core/security/password_hasher.dart';

const _brand = Color(0xFF7A3F19);
const _brandDark = Color(0xFF2D160B);
const _accent = Color(0xFFC68A43);
const _surface = Color(0xFFFFF8F0);
const _ink = Color(0xFF261B14);
const _languageStorageKey = 'app_language';
const _ownerPhoneStorageKey = 'configured_owner_phone';
const _ownerPasswordHashStorageKey = 'configured_owner_password_hash';
const _ownerSessionStorageKey = 'authenticated_owner_phone';

enum AppLanguage { en, mr }

class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    super.key,
    required this.language,
    required this.onChanged,
    required super.child,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  static AppLanguageScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLanguageScope>()!;
  }

  String t(String value) {
    if (language == AppLanguage.en) return value;
    return _mrTranslations[value] ?? value;
  }

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) {
    return language != oldWidget.language;
  }
}

String tr(BuildContext context, String value) =>
    AppLanguageScope.of(context).t(value);

List<TextInputFormatter> localizedTextInputFormatters(BuildContext context) {
  return AppLanguageScope.of(context).language == AppLanguage.mr
      ? const [_MarathiPhoneticInputFormatter()]
      : const [];
}

String localizedInputText(BuildContext context, String value) {
  return AppLanguageScope.of(context).language == AppLanguage.mr
      ? _MarathiPhoneticInputFormatter.transliterate(value)
      : value;
}

const Map<String, String> _mrTranslations = {
  'Digital Tailoring': 'डिजिटल टेलरिंग',
  'Track orders, manage customers, measurements, payments, and shop load from one mobile workspace.':
      'ऑर्डर, ग्राहक, मापे, पेमेंट आणि दुकानाचा लोड एका मोबाइल वर्कस्पेसमध्ये सांभाळा.',
  'Welcome back': 'पुन्हा स्वागत',
  'Manage your tailoring business, orders, and customers.':
      'तुमचा टेलरिंग व्यवसाय, ऑर्डर आणि ग्राहक सांभाळा.',
  'Set up your digital storefront and daily order capacity.':
      'तुमचे डिजिटल दुकान आणि रोजची ऑर्डर क्षमता सेट करा.',
  'Max orders per day': 'दिवसाला कमाल ऑर्डर',
  'Maximum orders you can stitch per day': 'दिवसाला शिवता येणाऱ्या कमाल ऑर्डर',
  'Get Started as Owner': 'मालक म्हणून सुरू करा',
  'Login': 'लॉगिन',
  'Phone Number': 'फोन नंबर',
  'Enter password': 'पासवर्ड टाका',
  'Biometric Login': 'बायोमेट्रिक लॉगिन',
  'Shop Details': 'दुकान माहिती',
  'Owner Name': 'मालकाचे नाव',
  'Shop Name': 'दुकानाचे नाव',
  'e.g. Lakshmi Tailors': 'उदा. लक्ष्मी टेलर्स',
  'Shop Address': 'दुकानाचा पत्ता',
  'Shop No., Street Name, Near Landmark': 'दुकान क्र., रस्ता, जवळची खूण',
  'Save & Continue': 'जतन करा आणि पुढे जा',
  "You're all set,": 'सर्व तयार आहे,',
  'Your catalogue, customers, and measurements are ready to go.':
      'तुमचा कॅटलॉग, ग्राहक आणि मापे तयार आहेत.',
  'Go to Dashboard': 'डॅशबोर्डवर जा',
  'Owner Dashboard': 'मालक डॅशबोर्ड',
  'Shop Orders': 'दुकान ऑर्डर',
  'Customers': 'ग्राहक',
  'Templates': 'टेम्पलेट्स',
  'My Shop': 'माझे दुकान',
  'Workers': 'कामगार',
  'Shop Settings': 'दुकान सेटिंग्ज',
  'Add Customer': 'ग्राहक जोडा',
  'New Order': 'नवीन ऑर्डर',
  'Active Subscription': 'सक्रिय सदस्यता',
  'Data is currently syncing to Supabase Cloud.':
      'डेटा सध्या Supabase Cloud शी सिंक होत आहे.',
  'Logout': 'लॉगआउट',
  'Dashboard': 'डॅशबोर्ड',
  'Orders': 'ऑर्डर',
  'Shop': 'दुकान',
  'Recent Orders': 'अलीकडील ऑर्डर',
  'Recent Customers': 'अलीकडील ग्राहक',
  'View all': 'सर्व पहा',
  'Quick Add': 'झटपट जोडा',
  'All Orders': 'सर्व ऑर्डर',
  'Pending': 'प्रलंबित',
  'Revenue': 'उत्पन्न',
  'Shop floor is at 90% load. Delivery might be tight.':
      'दुकानाचा लोड 90% आहे. डिलिव्हरी वेळ कमी असू शकतो.',
  'of daily capacity used': 'दैनिक क्षमतेचा वापर',
  'Search orders...': 'ऑर्डर शोधा...',
  'No orders found': 'ऑर्डर सापडल्या नाहीत',
  'Use the top-right New Order button to start a job.':
      'काम सुरू करण्यासाठी वरच्या उजवीकडील नवीन ऑर्डर बटण वापरा.',
  'Search by name or phone...': 'नाव किंवा फोनने शोधा...',
  'No customers found': 'ग्राहक सापडले नाहीत',
  'Tap + to add your first customer.': '+ टॅप करून पहिला ग्राहक जोडा.',
  'Order History': 'ऑर्डर इतिहास',
  'Details': 'तपशील',
  'This customer has no order history yet.':
      'या ग्राहकाचा ऑर्डर इतिहास अजून नाही.',
  'No measurements captured.': 'मापे नोंदलेली नाहीत.',
  'All templates are ready to deliver': 'सर्व टेम्पलेट्स डिलिव्हरीसाठी तयार',
  'Assignment': 'नेमणूक',
  'Customer': 'ग्राहक',
  'Order date': 'ऑर्डर तारीख',
  'Due date': 'देय तारीख',
  'Ord': 'ऑर्ड',
  'Due': 'देय',
  'Bal': 'बाकी',
  'Measure': 'मापे',
  'Assigned': 'नेमलेले',
  'Maker payment': 'मेकर पेमेंट',
  'Payments': 'पेमेंट्स',
  'created. Username': 'तयार. युजरनेम',
  'manager': 'मॅनेजर',
  'cutter': 'कटर',
  'maker': 'मेकर',
  'accountant': 'अकाउंटंट',
  'cutting': 'कटिंग',
  'shirt-maker': 'शर्ट-मेकर',
  'pant-maker': 'पॅन्ट-मेकर',
  'all': 'सर्व',
  'Create a worker in Shop before assigning work.':
      'काम देण्यापूर्वी दुकानात कामगार तयार करा.',
  'Assign worker': 'कामगार द्या',
  'Template status': 'टेम्पलेट स्थिती',
  'In Stitching': 'शिवणकामात',
  'Ready': 'तयार',
  'Hold': 'थांबवले',
  'Measurements': 'मापे',
  'Delivered': 'वितरित',
  'Cancel': 'रद्द',
  'Assign': 'द्या',
  'Update': 'अपडेट',
  'Mode': 'मोड',
  'Paying amount': 'देय रक्कम',
  'Promise note': 'वचन टीप',
  'Promise date': 'वचन तारीख',
  'Payment History': 'पेमेंट इतिहास',
  'Order Status': 'ऑर्डर स्थिती',
  'Order': 'ऑर्डर',
  'Weight': 'वजन',
  'Total': 'एकूण',
  'Payment': 'पेमेंट',
  'Date': 'तारीख',
  'Balance': 'बाकी',
  'Deliver when templates are Ready and balance is Rs 0, or add a promise note for DWP.':
      'टेम्पलेट्स तयार आणि बाकी Rs 0 असल्यावर डिलिव्हर करा, किंवा DWP साठी वचन टीप जोडा.',
  'Close': 'बंद',
  'Save': 'जतन',
  'Your custom garment templates': 'तुमचे कपड्यांचे टेम्पलेट्स',
  'Create Template': 'टेम्पलेट तयार करा',
  'No templates yet': 'टेम्पलेट्स नाहीत',
  'Tap the + button to create your first garment template.':
      '+ बटण टॅप करून पहिले टेम्पलेट तयार करा.',
  'Edit Template': 'टेम्पलेट संपादित करा',
  'Delete Template': 'टेम्पलेट हटवा',
  'Create Worker': 'कामगार तयार करा',
  'Worker Name': 'कामगाराचे नाव',
  'Mobile Number': 'मोबाइल नंबर',
  'Speciality': 'विशेषता',
  'Assign Roles': 'भूमिका द्या',
  'Create': 'तयार करा',
  'Enter worker details and select roles.':
      'कामगाराची माहिती भरा आणि भूमिका निवडा.',
  'Withdraw amount': 'काढण्याची रक्कम',
  'Wallet balance': 'वॉलेट शिल्लक',
  'Balance after payment': 'पेमेंटनंतर शिल्लक',
  'No worker payments recorded.': 'कामगार पेमेंट नोंदी नाहीत.',
  'Update Payment': 'पेमेंट अपडेट करा',
  'No templates created': 'टेम्पलेट्स तयार नाहीत',
  'Template name': 'टेम्पलेट नाव',
  'Charges': 'दर',
  'Maker charges': 'मेकर दर',
  'Custom fields': 'कस्टम फील्ड्स',
  'Worker': 'कामगार',
  'Wallet': 'वॉलेट',
  'No workers created': 'कामगार तयार नाहीत',
  'NEW ORDER': 'नवीन ऑर्डर',
  'Edit Order': 'ऑर्डर संपादित करा',
  'Select Customer': 'ग्राहक निवडा',
  'Add Cust.': 'ग्राहक जोडा',
  'Search customer by name or mobile': 'नाव किंवा मोबाइलने ग्राहक शोधा',
  'Clear customer': 'ग्राहक काढा',
  'Create Customer': 'ग्राहक तयार करा',
  'No customers yet': 'ग्राहक नाहीत',
  'Order Details': 'ऑर्डर तपशील',
  'Due Date': 'देय तारीख',
  'Order Due Date': 'ऑर्डर देय तारीख',
  'High Priority': 'उच्च प्राधान्य',
  'Add Order Items': 'ऑर्डर आयटम जोडा',
  'Add Template': 'टेम्पलेट जोडा',
  'No templates selected': 'टेम्पलेट निवडले नाही',
  'Additional Notes': 'अतिरिक्त टीपा',
  'Review & Payment': 'पुनरावलोकन आणि पेमेंट',
  'Order Summary': 'ऑर्डर सारांश',
  'No customer found': 'ग्राहक सापडला नाही',
  'Create a customer first, then continue this order.':
      'प्रथम ग्राहक तयार करा, नंतर ऑर्डर पुढे चालू ठेवा.',
  'Add one or more templates with quantity and measurements.':
      'प्रमाण आणि मापांसह एक किंवा अधिक टेम्पलेट्स जोडा.',
  'Qty': 'प्रमाण',
  'measurements assigned': 'मापे नेमली',
  'Paid Amount': 'भरलेली रक्कम',
  'Balance Amount': 'बाकी रक्कम',
  'Order Created': 'ऑर्डर तयार',
  'Save Changes': 'बदल जतन करा',
  'Advance Payment': 'अॅडव्हान्स पेमेंट',
  'Weight in kg': 'वजन किलोमध्ये',
  'PAYMENT MODE': 'पेमेंट मोड',
  'Status': 'स्थिती',
  'Select a customer and add a template.': 'ग्राहक निवडा आणि टेम्पलेट जोडा.',
  'Template': 'टेम्पलेट',
  'Template Status': 'टेम्पलेट स्थिती',
  'Take Measurement': 'माप घ्या',
  'Save Measurements': 'मापे जतन करा',
  'Customer Name': 'ग्राहकाचे नाव',
  'Short Address': 'लहान पत्ता',
  'Save Customer': 'ग्राहक जतन करा',
  'Create New Customer': 'नवीन ग्राहक तयार करा',
  'Edit Customer': 'ग्राहक संपादित करा',
  'Quantity': 'प्रमाण',
  'Line total': 'लाइन एकूण',
  'Measurements assigned for': 'मापे नेमली आहेत',
  'No measurements yet for this customer and template.':
      'या ग्राहक आणि टेम्पलेटसाठी अजून मापे नाहीत.',
  'Take Measurement -': 'माप घ्या -',
  'Template Name': 'टेम्पलेट नाव',
  'Maker Charges': 'मेकर दर',
  'Add custom field': 'कस्टम फील्ड जोडा',
  'e.g. APEX POINT': 'उदा. APEX POINT',
  'Save Template': 'टेम्पलेट जतन करा',
  'Language': 'भाषा',
  'English': 'इंग्रजी',
  'Marathi': 'मराठी',
  'Received': 'प्राप्त',
  'Bill': 'बिल',
  'Paid': 'भरले',
  'No address': 'पत्ता नाही',
  'Stitch': 'शिवण',
  'Measurement': 'मापे',
  'In stitching': 'शिवणकामात',
  'Total In stitching orders': 'एकूण शिवणकाम ऑर्डर',
  'Total in measurement state orders': 'एकूण मापे स्थिती ऑर्डर',
  'Total Payment received': 'एकूण पेमेंट प्राप्त',
  'Total Bill Amount': 'एकूण बिल रक्कम',
  'Reset Password': 'पासवर्ड रीसेट',
  'Reset your default password before continuing.':
      'पुढे जाण्यापूर्वी डिफॉल्ट पासवर्ड बदला.',
  'New password': 'नवीन पासवर्ड',
  'Confirm password': 'पासवर्ड पुष्टी करा',
  'Continue': 'पुढे चला',
  'Invalid mobile number or password.': 'मोबाइल नंबर किंवा पासवर्ड चुकीचा आहे.',
  'Total new orders': 'एकूण नवीन ऑर्डर',
  'Total ready orders': 'एकूण तयार ऑर्डर',
  'Closest first': 'जवळची आधी',
  'Total assigned templates': 'एकूण नेमलेले टेम्पलेट्स',
  'Total wallet balance': 'एकूण वॉलेट शिल्लक',
  'Assigned Templates': 'नेमलेले टेम्पलेट्स',
  'Due first': 'देय आधी',
  'No assigned templates': 'नेमलेले टेम्पलेट्स नाहीत',
  'Assigned work will appear here.': 'नेमलेले काम येथे दिसेल.',
  'Default password': 'डिफॉल्ट पासवर्ड',
  'Template ID': 'टेम्पलेट ID',
  'Rate': 'दर',
};

class _MarathiPhoneticInputFormatter extends TextInputFormatter {
  const _MarathiPhoneticInputFormatter();

  static const _halant = '\u094D';
  static const _vowels = {
    'aa': '\u0906',
    'ai': '\u0910',
    'au': '\u0914',
    'ee': '\u0908',
    'ii': '\u0908',
    'oo': '\u090A',
    'uu': '\u090A',
    'a': '\u0905',
    'i': '\u0907',
    'u': '\u0909',
    'e': '\u090F',
    'o': '\u0913',
  };
  static const _vowelSigns = {
    'aa': '\u093E',
    'ai': '\u0948',
    'au': '\u094C',
    'ee': '\u0940',
    'ii': '\u0940',
    'oo': '\u0942',
    'uu': '\u0942',
    'a': '',
    'i': '\u093F',
    'u': '\u0941',
    'e': '\u0947',
    'o': '\u094B',
  };
  static const _consonants = {
    'chh': '\u091B',
    'kh': '\u0916',
    'gh': '\u0918',
    'ch': '\u091A',
    'jh': '\u091D',
    'th': '\u0925',
    'dh': '\u0927',
    'ph': '\u092B',
    'bh': '\u092D',
    'sh': '\u0936',
    'tr': '\u0924\u094D\u0930',
    'gy': '\u091C\u094D\u091E',
    'ny': '\u091E',
    'ng': '\u0919',
    'ks': '\u0915\u094D\u0937',
    'k': '\u0915',
    'g': '\u0917',
    'c': '\u0915',
    'j': '\u091C',
    't': '\u0924',
    'd': '\u0926',
    'n': '\u0928',
    'p': '\u092A',
    'f': '\u092B',
    'b': '\u092C',
    'm': '\u092E',
    'y': '\u092F',
    'r': '\u0930',
    'l': '\u0932',
    'v': '\u0935',
    'w': '\u0935',
    's': '\u0938',
    'h': '\u0939',
  };

  static final _vowelKeys = _vowels.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  static final _consonantKeys = _consonants.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final text = newValue.text;
    final trailingMatch = RegExp(r'[A-Za-z]+$').firstMatch(text);
    final trailingStart = trailingMatch?.start ?? text.length;
    final converted = transliterate(text.substring(0, trailingStart)) +
        text.substring(trailingStart);
    if (converted == text) return newValue;
    return newValue.copyWith(
      text: converted,
      selection: TextSelection.collapsed(offset: converted.length),
      composing: TextRange.empty,
    );
  }

  static String transliterate(String text) {
    final output = StringBuffer();
    var index = 0;
    final lower = text.toLowerCase();
    while (index < text.length) {
      final char = lower[index];
      if (!_isAsciiLetter(char)) {
        output.write(text[index]);
        index++;
        continue;
      }

      final consonant = _matchAt(lower, index, _consonantKeys);
      if (consonant != null) {
        final base = _consonants[consonant]!;
        final nextIndex = index + consonant.length;
        final vowel = _matchAt(lower, nextIndex, _vowelKeys);
        if (vowel != null) {
          output.write(base);
          output.write(_vowelSigns[vowel]);
          index = nextIndex + vowel.length;
          continue;
        }
        final nextConsonant = _matchAt(lower, nextIndex, _consonantKeys);
        output.write(base);
        if (nextConsonant != null) output.write(_halant);
        index = nextIndex;
        continue;
      }

      final vowel = _matchAt(lower, index, _vowelKeys);
      if (vowel != null) {
        output.write(_vowels[vowel]);
        index += vowel.length;
        continue;
      }

      output.write(text[index]);
      index++;
    }
    return output.toString();
  }

  static String? _matchAt(String text, int index, List<String> keys) {
    if (index >= text.length) return null;
    for (final key in keys) {
      if (text.startsWith(key, index)) return key;
    }
    return null;
  }

  static bool _isAsciiLetter(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 97 && code <= 122) || (code >= 65 && code <= 90);
  }
}

class StoreManagementApp extends StatefulWidget {
  const StoreManagementApp({super.key});

  @override
  State<StoreManagementApp> createState() => _StoreManagementAppState();
}

class _StoreManagementAppState extends State<StoreManagementApp> {
  _Stage _stage = _Stage.launch;
  int _tab = 0;
  bool _showShopSettings = false;
  AppLanguage _language = AppLanguage.en;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  ShopWorker? _loggedInWorker;
  ShopWorker? _passwordResetWorker;
  bool _isResettingOwnerPassword = false;
  bool _ownerCredentialsLoaded = false;
  bool _isOwnerSessionActive = false;
  String? _ownerPasswordHash;
  late final Future<void> _ownerCredentialsFuture;

  final List<TailorCustomer> _customers = [
    TailorCustomer(
      name: 'Aarav Mehta',
      phone: '9876543410',
      address: 'Main road, Pune',
      measurementsByTemplate: {
        'Men Shirt': TemplateMeasurement(
          templateName: 'Men Shirt',
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          values: {
            'Chest': '39',
            'Waist': '34',
            'Shoulder': '17',
            'Sleeve': '24',
            'Length': '29',
          },
        ),
      },
    ),
    TailorCustomer(
      name: 'Meera Shah',
      phone: '9988776655',
      address: 'Station Road, Mumbai',
      measurementsByTemplate: {
        'Kurti': TemplateMeasurement(
          templateName: 'Kurti',
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          values: {
            'Bust': '36',
            'Waist': '30',
            'Hip': '38',
            'Armhole': '15',
            'Length': '42',
          },
        ),
      },
    ),
  ];

  final List<TailorOrder> _orders = [
    TailorOrder(
      id: 'ORD-1042',
      customerName: 'Aarav Mehta',
      items: [
        OrderTemplateItem(
          templateName: 'Men Shirt',
          quantity: 2,
          status: 'Ready',
          charges: 900,
          makerCharges: 250,
          measurementUpdatedAt:
              DateTime.now().subtract(const Duration(days: 3)),
          assignedWorkerByUnit: {0: '9876502222', 1: '9876502222'},
          workerPaymentStatusByUnit: {0: 'Paid-Worker', 1: 'Paid-Worker'},
          measurements: {
            'Chest': '39',
            'Waist': '34',
            'Shoulder': '17',
            'Sleeve': '24',
            'Length': '29',
          },
        ),
      ],
      orderDate: DateTime.now().subtract(const Duration(days: 4)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: 'In Stitching',
      paymentMode: 'UPI',
      advancePayment: 800,
      payments: [
        OrderPayment(
          amount: 800,
          mode: 'UPI',
          paidAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ],
      weightKg: 1.8,
      tailor: 'Master Tailor',
      priority: true,
      notes: 'Add reference pocket style.',
    ),
    TailorOrder(
      id: 'ORD-1041',
      customerName: 'Meera Shah',
      items: [
        OrderTemplateItem(
          templateName: 'Kurti',
          quantity: 1,
          status: 'In Stitching',
          charges: 1800,
          makerCharges: 600,
          measurementUpdatedAt:
              DateTime.now().subtract(const Duration(days: 2)),
          assignedWorkerByUnit: {0: '9876502222'},
          measurements: {
            'Bust': '36',
            'Waist': '30',
            'Hip': '38',
            'Armhole': '15',
            'Length': '42',
          },
        ),
      ],
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
      dueDate: DateTime.now().add(const Duration(days: 5)),
      status: 'In Stitching',
      paymentMode: 'Cash',
      advancePayment: 1000,
      payments: [
        OrderPayment(
          amount: 1000,
          mode: 'Cash',
          paidAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
      weightKg: 2.4,
      tailor: 'Shop Manager',
      priority: false,
      notes: 'Embroidery on sleeves.',
    ),
  ];

  final List<GarmentTemplate> _templates = [
    GarmentTemplate(
      name: 'Men Shirt',
      charges: 900,
      makerCharges: 250,
      fields: ['Chest', 'Waist', 'Shoulder', 'Sleeve', 'Length'],
    ),
    GarmentTemplate(
      name: 'Kurti',
      charges: 1800,
      makerCharges: 600,
      fields: ['Bust', 'Waist', 'Hip', 'Armhole', 'Length'],
    ),
  ];

  final List<ShopWorker> _workers = [
    const ShopWorker(
      name: 'Ramesh Pawar',
      mobile: '9876501111',
      speciality: 'cutting',
      roles: ['cutter'],
      username: '9876501111',
      defaultPassword: 'RameshPawar501111',
      password: 'RameshPawar501111',
      mustResetPassword: true,
      walletBalance: 0,
    ),
    const ShopWorker(
      name: 'Sahil Khan',
      mobile: '9876502222',
      speciality: 'shirt-maker',
      roles: ['maker'],
      username: '9876502222',
      defaultPassword: 'SahilKhan502222',
      password: 'SahilKhan502222',
      mustResetPassword: true,
      walletBalance: 500,
    ),
    const ShopWorker(
      name: 'Pooja Jadhav',
      mobile: '9876503333',
      speciality: 'pant-maker',
      roles: ['accountant', 'maker'],
      username: '9876503333',
      defaultPassword: 'PoojaJadhav503333',
      password: 'PoojaJadhav503333',
      mustResetPassword: true,
      walletBalance: 600,
    ),
    const ShopWorker(
      name: 'Nikhil Patil',
      mobile: '9876504444',
      speciality: 'all',
      roles: ['manager', 'cutter', 'maker'],
      username: '9876504444',
      defaultPassword: 'NikhilPatil504444',
      password: 'NikhilPatil504444',
      mustResetPassword: true,
      walletBalance: 250,
    ),
  ];

  late ShopProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = ShopProfile(
      ownerName: AppConfig.ownerName,
      shopName: AppConfig.shopName,
      phone: AppConfig.ownerPhone,
      address: AppConfig.shopAddress,
      maxOrdersPerDay: 12,
      openDays: '24/7',
    );
    _loadLanguage();
    _ownerCredentialsFuture = _loadOwnerCredentials();
    _completeLaunchAnimation();
  }

  Future<void> _completeLaunchAnimation() async {
    await Future<void>.delayed(const Duration(seconds: 15));
    await _ownerCredentialsFuture;
    if (!mounted || _stage != _Stage.launch) return;
    setState(() => _stage = _isOwnerSessionActive ? _Stage.home : _Stage.login);
  }

  Future<void> _loadLanguage() async {
    final code = await _storage.read(key: _languageStorageKey);
    if (!mounted) return;
    setState(() {
      _language = code == 'mr' ? AppLanguage.mr : AppLanguage.en;
    });
  }

  Future<void> _setLanguage(AppLanguage language) async {
    setState(() => _language = language);
    await _storage.write(
      key: _languageStorageKey,
      value: language == AppLanguage.mr ? 'mr' : 'en',
    );
  }

  Future<void> _loadOwnerCredentials() async {
    final storedPhone = await _storage.read(key: _ownerPhoneStorageKey);
    final passwordHash = await _storage.read(key: _ownerPasswordHashStorageKey);
    final authenticatedPhone =
        await _storage.read(key: _ownerSessionStorageKey);
    if (!mounted) return;
    setState(() {
      final hasChangedPassword =
          storedPhone == _profile.phone && passwordHash != null;
      if (hasChangedPassword) {
        _ownerPasswordHash = passwordHash;
      }
      _isOwnerSessionActive =
          hasChangedPassword && authenticatedPhone == _profile.phone;
      _ownerCredentialsLoaded = true;
    });
  }

  ShopWorker get _ownerPasswordResetIdentity => ShopWorker(
        name: _profile.ownerName,
        mobile: _profile.phone,
        speciality: 'owner',
        roles: const ['owner'],
        username: _profile.phone,
        defaultPassword: AppConfig.ownerDefaultPassword,
        password: AppConfig.ownerDefaultPassword,
        mustResetPassword: true,
        walletBalance: 0,
      );

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      language: _language,
      onChanged: _setLanguage,
      child: MaterialApp(
        title: 'Digital Tailoring',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: _surface,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _brand,
            primary: _brand,
            secondary: _accent,
            surface: const Color(0xFFFFFBF6),
          ),
          textTheme: ThemeData.light().textTheme.apply(
                bodyColor: _ink,
                displayColor: _ink,
              ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: _surface,
            foregroundColor: _ink,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: const Color(0xFFFFFBF6),
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFEBD8C4)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        home: switch (_stage) {
          _Stage.launch => const LaunchScreen(),
          _Stage.welcome => WelcomeScreen(
              onLogin: () => setState(() => _stage = _Stage.login),
            ),
          _Stage.login => LoginScreen(
              configuredPhone: _profile.phone,
              onLogin: _attemptLogin,
            ),
          _Stage.passwordReset => PasswordResetScreen(
              worker: _passwordResetWorker!,
              onPasswordChanged: _resetPassword,
            ),
          _Stage.setup => SetupScreen(
              profile: _profile,
              onBack: () => setState(() => _stage = _Stage.welcome),
              onComplete: (profile) {
                setState(() {
                  _profile = profile;
                  _stage = _Stage.allSet;
                });
              },
            ),
          _Stage.allSet => AllSetScreen(
              shopName: _profile.shopName,
              onDashboard: () => setState(() => _stage = _Stage.home),
            ),
          _Stage.home => HomeShell(
              tab: _tab,
              showShopSettings: _showShopSettings,
              loggedInWorker: _loggedInWorker,
              profile: _profile,
              customers: _customers,
              orders: _orders,
              templates: _templates,
              workers: _workers,
              onTabChanged: (value) => setState(() {
                _tab = value;
                _showShopSettings = false;
              }),
              onShopSettingsChanged: (value) =>
                  setState(() => _showShopSettings = value),
              onLogout: _logout,
              onCustomerSaved: _saveCustomer,
              onTemplateSaved: _saveTemplate,
              onTemplateDeleted: _deleteTemplate,
              onOrderSaved: _saveOrder,
              onWorkerSaved: _saveWorker,
              onWorkerPaymentRecorded: _recordWorkerPayment,
              onTemplateAssigned: _assignOrderTemplateWorker,
            ),
        },
      ),
    );
  }

  LoginResult _attemptLogin(String username, String password) {
    final normalized = username.trim();
    final enteredPassword = password.trim();
    if (normalized == _profile.phone) {
      if (!_ownerCredentialsLoaded) {
        return const LoginResult.failure(
          'Owner account is still loading. Please try again.',
        );
      }
      final hasNewPassword = _ownerPasswordHash != null;
      final validPassword = hasNewPassword
          ? const PasswordHasher().verify(
              enteredPassword,
              _ownerPasswordHash!,
            )
          : enteredPassword == AppConfig.ownerDefaultPassword;
      if (!validPassword) {
        return const LoginResult.failure(
          'Invalid mobile number or password.',
        );
      }
      setState(() {
        _tab = 0;
        _showShopSettings = false;
        if (hasNewPassword) {
          _isOwnerSessionActive = true;
          _loggedInWorker = null;
          _passwordResetWorker = null;
          _isResettingOwnerPassword = false;
          _stage = _Stage.home;
        } else {
          _isResettingOwnerPassword = true;
          _passwordResetWorker = _ownerPasswordResetIdentity;
          _stage = _Stage.passwordReset;
        }
      });
      if (hasNewPassword) {
        unawaited(_storage.write(
          key: _ownerSessionStorageKey,
          value: _profile.phone,
        ));
      }
      return LoginResult.success(forceReset: !hasNewPassword);
    }

    for (final worker in _workers) {
      if ((worker.mobile == normalized || worker.username == normalized) &&
          worker.password == enteredPassword) {
        setState(() {
          _tab = 0;
          _showShopSettings = false;
          _isResettingOwnerPassword = false;
          if (worker.mustResetPassword) {
            _passwordResetWorker = worker;
            _stage = _Stage.passwordReset;
          } else {
            _loggedInWorker = worker;
            _passwordResetWorker = null;
            _stage = _Stage.home;
          }
        });
        return LoginResult.success(forceReset: worker.mustResetPassword);
      }
    }

    return const LoginResult.failure('Invalid mobile number or password.');
  }

  Future<void> _resetPassword(String password) async {
    if (!_isResettingOwnerPassword) {
      _resetWorkerPassword(password);
      return;
    }
    final passwordHash = const PasswordHasher().hash(password);
    await _storage.write(key: _ownerPhoneStorageKey, value: _profile.phone);
    await _storage.write(
      key: _ownerPasswordHashStorageKey,
      value: passwordHash,
    );
    await _storage.write(
      key: _ownerSessionStorageKey,
      value: _profile.phone,
    );
    if (!mounted) return;
    setState(() {
      _ownerPasswordHash = passwordHash;
      _isOwnerSessionActive = true;
      _isResettingOwnerPassword = false;
      _loggedInWorker = null;
      _passwordResetWorker = null;
      _tab = 0;
      _showShopSettings = false;
      _stage = _Stage.home;
    });
  }

  Future<void> _logout() async {
    await _storage.delete(key: _ownerSessionStorageKey);
    if (!mounted) return;
    setState(() {
      _isOwnerSessionActive = false;
      _loggedInWorker = null;
      _passwordResetWorker = null;
      _tab = 0;
      _showShopSettings = false;
      _stage = _Stage.login;
    });
  }

  void _resetWorkerPassword(String password) {
    final worker = _passwordResetWorker;
    if (worker == null) return;
    setState(() {
      final index = _workers.indexWhere((item) => item.mobile == worker.mobile);
      if (index < 0) return;
      final updated = _workers[index].copyWith(
        password: password,
        mustResetPassword: false,
      );
      _workers[index] = updated;
      _loggedInWorker = updated;
      _passwordResetWorker = null;
      _isResettingOwnerPassword = false;
      _tab = 0;
      _showShopSettings = false;
      _stage = _Stage.home;
    });
  }

  void _saveCustomer(TailorCustomer customer) {
    setState(() {
      final index =
          _customers.indexWhere((item) => item.phone == customer.phone);
      if (index >= 0) {
        _customers[index] = customer.copyWith(
          measurementsByTemplate: _customers[index].measurementsByTemplate,
        );
      } else {
        _customers.insert(0, customer);
      }
    });
  }

  void _saveTemplate(GarmentTemplate template) {
    setState(() {
      final index = _templates.indexWhere((item) => item.name == template.name);
      if (index >= 0) {
        _templates[index] = template;
      } else {
        _templates.insert(0, template);
      }
    });
  }

  void _deleteTemplate(GarmentTemplate template) {
    setState(() => _templates.remove(template));
  }

  void _saveOrder(TailorOrder order) {
    setState(() {
      final index = _orders.indexWhere((item) => item.id == order.id);
      if (index >= 0) {
        _orders[index] = order;
      } else {
        _orders.insert(0, order);
      }
    });
  }

  void _saveWorker(ShopWorker worker) {
    setState(() {
      final index = _workers.indexWhere((item) => item.mobile == worker.mobile);
      if (index >= 0) {
        _workers[index] = worker;
      } else {
        _workers.insert(0, worker);
      }
    });
  }

  void _recordWorkerPayment({
    required ShopWorker worker,
    required int amount,
  }) {
    if (amount <= 0) return;
    setState(() {
      final workerIndex =
          _workers.indexWhere((item) => item.mobile == worker.mobile);
      if (workerIndex < 0) return;
      final current = _workers[workerIndex];
      final updated = current.copyWith(
        walletBalance: current.walletBalance - amount,
        payments: [
          WorkerPayment(
            amount: amount,
            paidAt: DateTime.now(),
            note: 'Worker withdrawal',
          ),
          ...current.payments,
        ],
      );
      _workers[workerIndex] = updated;
      if (_loggedInWorker?.mobile == updated.mobile) {
        _loggedInWorker = updated;
      }

      for (var orderIndex = 0; orderIndex < _orders.length; orderIndex++) {
        final order = _orders[orderIndex];
        var changed = false;
        final items = <OrderTemplateItem>[];
        for (final item in order.items) {
          if (item.status != 'Ready') {
            items.add(item);
            continue;
          }
          final statuses = Map<int, String>.of(item.workerPaymentStatusByUnit);
          for (final entry in item.assignedWorkerByUnit.entries) {
            if (entry.value == worker.mobile) {
              statuses[entry.key] = 'Paid-Worker';
              changed = true;
            }
          }
          items.add(
            changed ? item.copyWith(workerPaymentStatusByUnit: statuses) : item,
          );
        }
        if (changed) {
          _orders[orderIndex] = order.copyWith(items: items);
        }
      }
    });
  }

  void _assignOrderTemplateWorker({
    required String orderId,
    required int itemIndex,
    required int unitIndex,
    required ShopWorker worker,
    String? status,
  }) {
    setState(() {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex < 0) return;

      final order = _orders[orderIndex];
      if (itemIndex >= order.items.length) return;
      final item = order.items[itemIndex];
      final wasReady = item.status == 'Ready';
      final previousWorkerMobile = item.assignedWorkerByUnit[unitIndex];
      final paymentStatuses =
          Map<int, String>.of(item.workerPaymentStatusByUnit)
            ..remove(unitIndex);
      final items = [...order.items];
      final nextStatus = status ?? 'In Stitching';
      final becomesReady = nextStatus == 'Ready';
      items[itemIndex] = item.copyWith(
        status: nextStatus,
        assignedWorkerByUnit: {
          ...item.assignedWorkerByUnit,
          unitIndex: worker.mobile,
        },
        workerPaymentStatusByUnit: paymentStatuses,
      );
      _orders[orderIndex] = order.copyWith(
        status: nextStatus,
        items: items,
      );

      if (wasReady &&
          previousWorkerMobile != null &&
          (!becomesReady || previousWorkerMobile != worker.mobile)) {
        _updateWorkerWallet(previousWorkerMobile, -item.makerCharges);
      }
      if (becomesReady &&
          (!wasReady || previousWorkerMobile != worker.mobile)) {
        _updateWorkerWallet(worker.mobile, item.makerCharges);
      }
    });
  }

  void _updateWorkerWallet(String mobile, int amount) {
    final workerIndex =
        _workers.indexWhere((worker) => worker.mobile == mobile);
    if (workerIndex < 0) return;
    final worker = _workers[workerIndex];
    final updated = worker.copyWith(
      walletBalance: worker.walletBalance + amount,
    );
    _workers[workerIndex] = updated;
    if (_loggedInWorker?.mobile == updated.mobile) {
      _loggedInWorker = updated;
    }
  }
}

enum _Stage { launch, welcome, login, passwordReset, setup, allSet, home }

class LoginResult {
  const LoginResult._({
    required this.success,
    this.forceReset = false,
    this.error,
  });

  const LoginResult.success({bool forceReset = false})
      : this._(success: true, forceReset: forceReset);

  const LoginResult.failure(String error)
      : this._(success: false, error: error);

  final bool success;
  final bool forceReset;
  final String? error;
}

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _ease;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..forward();
    _ease = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandDark,
      body: AnimatedBuilder(
        animation: _ease,
        builder: (context, _) {
          final progress = _ease.value;
          final logoScale = 0.82 +
              (0.18 *
                  Curves.easeOutBack.transform(
                    progress.clamp(0.0, 0.85) / 0.85,
                  ));
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [_brand, _brandDark],
                  ),
                ),
              ),
              CustomPaint(painter: _LaunchStitchPainter(progress)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: logoScale,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 360),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEAD2),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.4),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/tailoring_login.gif',
                              height: 220,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: progress.clamp(0.0, 1.0),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(
                            Icons.content_cut,
                            color: Color(0xFFFFEAD2),
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: progress,
                        child: Text(
                          tr(context, 'Digital Tailoring'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 210,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            valueColor: const AlwaysStoppedAnimation(_accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LaunchStitchPainter extends CustomPainter {
  const _LaunchStitchPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final threadPaint = Paint()
      ..color = const Color(0xFFFFEAD2).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final needlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = _accent.withValues(alpha: 0.85);
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.62)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.42,
        size.width * 0.38,
        size.height * 0.72,
        size.width * 0.54,
        size.height * 0.53,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.36,
        size.width * 0.78,
        size.height * 0.68,
        size.width * 0.92,
        size.height * 0.48,
      );
    final metricIterator = path.computeMetrics().iterator;
    if (!metricIterator.moveNext()) return;
    final metric = metricIterator.current;
    final visible = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(visible, threadPaint);

    for (var i = 0; i < 11; i++) {
      final offset =
          metric.getTangentForOffset(metric.length * i / 10)?.position;
      if (offset == null) continue;
      final active = progress >= i / 10;
      canvas.drawCircle(offset, active ? 4 : 2, dotPaint);
    }

    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent == null) return;
    final center = tangent.position;
    final end = Offset(center.dx + 20, center.dy - 24);
    canvas.drawLine(center, end, needlePaint);
    canvas.drawCircle(end, 3, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _LaunchStitchPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onLogin,
  });

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/all_set_mannequin.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, _brandDark],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    tr(context, 'Digital Tailoring'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(context,
                        'Track orders, manage customers, measurements, payments, and shop load from one mobile workspace.'),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: const Color(0xFFFFEAD2)),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onLogin,
                    icon: const Icon(Icons.login),
                    label: Text(tr(context, 'Login')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.configuredPhone,
    required this.onLogin,
  });

  final String configuredPhone;
  final LoginResult Function(String username, String password) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.configuredPhone);
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 850),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 18 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFF1E0),
                                    Color(0xFFFFFBF6),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Image.asset(
                                  'assets/images/tailoring_login.gif',
                                  height: 170,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          tr(context, 'Welcome back'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(context,
                              'Manage your tailoring business, orders, and customers.'),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: tr(context, 'Phone Number'),
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: tr(context, 'Enter password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final result =
                                  widget.onLogin(_phone.text, _password.text);
                              if (!result.success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result.error ??
                                        'Invalid mobile number or password.'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.login),
                          label: Text(tr(context, 'Login')),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            final result =
                                widget.onLogin(_phone.text, _password.text);
                            if (!result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.error ??
                                      'Invalid mobile number or password.'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.fingerprint),
                          label: Text(tr(context, 'Biometric Login')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({
    super.key,
    required this.worker,
    required this.onPasswordChanged,
  });

  final ShopWorker worker;
  final ValueChanged<String> onPasswordChanged;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'Reset Password'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.worker.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr(context,
                              'Reset your default password before continuing.'),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: tr(context, 'New password'),
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.length < 6) {
                              return 'Use at least 6 characters.';
                            }
                            if (text == widget.worker.defaultPassword) {
                              return 'Choose a new password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirm,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: tr(context, 'Confirm password'),
                            prefixIcon: const Icon(Icons.verified_outlined),
                          ),
                          validator: (value) {
                            if ((value ?? '') != _password.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            widget.onPasswordChanged(_password.text.trim());
                          },
                          child: Text(tr(context, 'Continue')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.profile,
    required this.onBack,
    required this.onComplete,
  });

  final ShopProfile profile;
  final VoidCallback onBack;
  final ValueChanged<ShopProfile> onComplete;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _owner;
  late final TextEditingController _shop;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late double _capacity;

  @override
  void initState() {
    super.initState();
    _owner = TextEditingController(text: widget.profile.ownerName);
    _shop = TextEditingController(text: widget.profile.shopName);
    _phone = TextEditingController(text: widget.profile.phone);
    _address = TextEditingController(text: widget.profile.address);
    _capacity = widget.profile.maxOrdersPerDay.toDouble();
  }

  @override
  void dispose() {
    _owner.dispose();
    _shop.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: widget.onBack)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(tr(context, 'Shop Details'),
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(tr(context,
                'Set up your digital storefront and daily order capacity.')),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _owner,
                    inputFormatters: localizedTextInputFormatters(context),
                    decoration: InputDecoration(
                      labelText: tr(context, 'Owner Name'),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shop,
                    inputFormatters: localizedTextInputFormatters(context),
                    decoration: InputDecoration(
                      labelText: tr(context, 'Shop Name'),
                      hintText: tr(context, 'e.g. Lakshmi Tailors'),
                      prefixIcon: const Icon(Icons.storefront_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Phone Number'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    inputFormatters: localizedTextInputFormatters(context),
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Shop Address'),
                      hintText:
                          tr(context, 'Shop No., Street Name, Near Landmark'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(context, 'Max orders per day'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${tr(context, 'Maximum orders you can stitch per day')}: ${_capacity.round()}',
                          ),
                          Slider(
                            value: _capacity,
                            min: 4,
                            max: 30,
                            divisions: 26,
                            label: '${_capacity.round()}',
                            onChanged: (value) =>
                                setState(() => _capacity = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(tr(context, 'Save & Continue')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onComplete(
      ShopProfile(
        ownerName: localizedInputText(context, _owner.text).trim(),
        shopName: localizedInputText(context, _shop.text).trim(),
        phone: _phone.text.trim(),
        address: localizedInputText(context, _address.text).trim(),
        maxOrdersPerDay: _capacity.round(),
        openDays: '24/7',
      ),
    );
  }
}

class AllSetScreen extends StatelessWidget {
  const AllSetScreen(
      {super.key, required this.shopName, required this.onDashboard});

  final String shopName;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  'assets/images/all_set_mannequin.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(tr(context, "You're all set,"),
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              shopName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(tr(context,
                'Your catalogue, customers, and measurements are ready to go.')),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onDashboard,
              icon: const Icon(Icons.dashboard_outlined),
              label: Text(tr(context, 'Go to Dashboard')),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.tab,
    required this.showShopSettings,
    required this.loggedInWorker,
    required this.profile,
    required this.customers,
    required this.orders,
    required this.templates,
    required this.workers,
    required this.onTabChanged,
    required this.onShopSettingsChanged,
    required this.onLogout,
    required this.onCustomerSaved,
    required this.onTemplateSaved,
    required this.onTemplateDeleted,
    required this.onOrderSaved,
    required this.onWorkerSaved,
    required this.onWorkerPaymentRecorded,
    required this.onTemplateAssigned,
  });

  final int tab;
  final bool showShopSettings;
  final ShopWorker? loggedInWorker;
  final ShopProfile profile;
  final List<TailorCustomer> customers;
  final List<TailorOrder> orders;
  final List<GarmentTemplate> templates;
  final List<ShopWorker> workers;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<bool> onShopSettingsChanged;
  final VoidCallback onLogout;
  final ValueChanged<TailorCustomer> onCustomerSaved;
  final ValueChanged<GarmentTemplate> onTemplateSaved;
  final ValueChanged<GarmentTemplate> onTemplateDeleted;
  final ValueChanged<TailorOrder> onOrderSaved;
  final ValueChanged<ShopWorker> onWorkerSaved;
  final void Function({
    required ShopWorker worker,
    required int amount,
  }) onWorkerPaymentRecorded;
  final void Function({
    required String orderId,
    required int itemIndex,
    required int unitIndex,
    required ShopWorker worker,
    String? status,
  }) onTemplateAssigned;

  @override
  Widget build(BuildContext context) {
    final worker = loggedInWorker;
    final isOwner = worker == null;
    final isManagerWorker = worker != null &&
        (worker.roles.contains('manager') ||
            worker.roles.contains('accountant'));
    final titles = isOwner
        ? [
            'Owner Dashboard',
            'Shop Orders',
            'Customers',
            'Templates',
            'My Shop'
          ]
        : isManagerWorker
            ? ['Dashboard', 'Shop Orders', 'Customers', 'Workers']
            : ['Dashboard'];
    final currentTab = tab.clamp(0, titles.length - 1).toInt();
    final title = titles[currentTab];
    final backgroundColor = _sessionBackground(worker);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(tr(context, title)),
        backgroundColor: backgroundColor,
        actions: [
          if (!isOwner || (currentTab == 4 && showShopSettings))
            const _LanguageSwitcher(),
          if (isOwner) ...[
            if (currentTab == 4)
              IconButton(
                tooltip:
                    tr(context, showShopSettings ? 'Workers' : 'Shop Settings'),
                onPressed: () => onShopSettingsChanged(!showShopSettings),
                icon: Icon(showShopSettings
                    ? Icons.groups_outlined
                    : Icons.settings_outlined),
              )
            else if (currentTab == 2)
              IconButton(
                tooltip: tr(context, 'Add Customer'),
                onPressed: () => _openCustomer(context),
                icon: const Icon(Icons.person_add_alt_1_outlined),
              )
            else
              IconButton(
                tooltip: tr(context, 'New Order'),
                onPressed: () => _openOrder(context),
                icon: const Icon(Icons.add_business_outlined),
              ),
          ] else ...[
            if (isManagerWorker && currentTab == 1)
              IconButton(
                tooltip: tr(context, 'New Order'),
                onPressed: () => _openOrder(context),
                icon: const Icon(Icons.add_business_outlined),
              ),
            if (isManagerWorker && currentTab == 2)
              IconButton(
                tooltip: tr(context, 'Add Customer'),
                onPressed: () => _openCustomer(context),
                icon: const Icon(Icons.person_add_alt_1_outlined),
              ),
            IconButton(
              tooltip: tr(context, 'Logout'),
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ],
      ),
      drawer: worker != null && !isManagerWorker
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: _brand,
                        child: Icon(Icons.storefront, color: Colors.white),
                      ),
                      title: Text(worker?.name ?? profile.shopName),
                      subtitle: Text(worker == null
                          ? profile.ownerName
                          : worker.roles
                              .map((role) => tr(context, role))
                              .join(', ')),
                    ),
                    const Divider(),
                    _DrawerTile(Icons.dashboard_outlined, titles[0], 0,
                        currentTab, onTabChanged),
                    if (isOwner || isManagerWorker)
                      _DrawerTile(Icons.receipt_long_outlined, 'Shop Orders', 1,
                          currentTab, onTabChanged),
                    if (isOwner || isManagerWorker)
                      _DrawerTile(Icons.people_outline, 'Customers', 2,
                          currentTab, onTabChanged),
                    if (isOwner)
                      _DrawerTile(Icons.design_services_outlined, 'Templates',
                          3, currentTab, onTabChanged),
                    if (isOwner)
                      _DrawerTile(Icons.store_mall_directory_outlined,
                          'My Shop', 4, currentTab, onTabChanged),
                    if (isManagerWorker)
                      _DrawerTile(Icons.groups_outlined, 'Workers', 3,
                          currentTab, onTabChanged),
                    const Divider(),
                    if (isOwner)
                      ListTile(
                        leading: const Icon(Icons.cloud_done_outlined),
                        title: Text(tr(context, 'Active Subscription')),
                        subtitle: Text(
                          tr(context,
                              'Data is currently syncing to Supabase Cloud.'),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(tr(context, 'Logout')),
                      onTap: onLogout,
                    ),
                  ],
                ),
              ),
            ),
      body: SafeArea(
        child: isOwner
            ? switch (currentTab) {
                0 => DashboardTab(
                    profile: profile,
                    customers: customers,
                    orders: orders,
                    workers: workers,
                    onNewOrder: () => _openOrder(context),
                    onAddCustomer: () => _openCustomer(context),
                    onOrderSaved: onOrderSaved,
                    onTemplateAssigned: onTemplateAssigned,
                  ),
                1 => OrdersTab(
                    orders: orders,
                    workers: workers,
                    onEditOrder: (order) => _openOrder(context, order: order),
                    onOrderSaved: onOrderSaved,
                    onTemplateAssigned: onTemplateAssigned,
                  ),
                2 => CustomersTab(
                    customers: customers,
                    orders: orders,
                    onAddCustomer: () => _openCustomer(context),
                    onOrderSaved: onOrderSaved,
                  ),
                3 => TemplatesTab(
                    templates: templates,
                    onSave: onTemplateSaved,
                    onDelete: onTemplateDeleted,
                  ),
                4 => ProfileTab(
                    profile: profile,
                    templates: templates,
                    workers: workers,
                    showSettings: showShopSettings,
                    onTemplateSaved: onTemplateSaved,
                    onTemplateDeleted: onTemplateDeleted,
                    onWorkerSaved: onWorkerSaved,
                    onWorkerPaymentRecorded: onWorkerPaymentRecorded,
                  ),
                _ => const SizedBox.shrink(),
              }
            : isManagerWorker
                ? switch (currentTab) {
                    0 => ManagerDashboardTab(
                        orders: orders,
                        workers: workers,
                        onOrderSaved: onOrderSaved,
                        onTemplateAssigned: onTemplateAssigned,
                      ),
                    1 => OrdersTab(
                        orders: orders,
                        workers: workers,
                        onEditOrder: (order) =>
                            _openOrder(context, order: order),
                        onOrderSaved: onOrderSaved,
                        onTemplateAssigned: onTemplateAssigned,
                      ),
                    2 => CustomersTab(
                        customers: customers,
                        orders: orders,
                        onAddCustomer: () => _openCustomer(context),
                        onOrderSaved: onOrderSaved,
                      ),
                    3 => ProfileTab(
                        profile: profile,
                        templates: templates,
                        workers: workers,
                        showSettings: false,
                        onTemplateSaved: onTemplateSaved,
                        onTemplateDeleted: onTemplateDeleted,
                        onWorkerSaved: onWorkerSaved,
                        onWorkerPaymentRecorded: onWorkerPaymentRecorded,
                      ),
                    _ => const SizedBox.shrink(),
                  }
                : WorkerTaskDashboardTab(
                    worker: worker,
                    orders: orders,
                    onTemplateReady: onTemplateAssigned,
                  ),
      ),
      bottomNavigationBar: !isOwner && !isManagerWorker
          ? null
          : NavigationBar(
              selectedIndex: currentTab,
              onDestinationSelected: onTabChanged,
              destinations: isOwner
                  ? [
                      NavigationDestination(
                        icon: const Icon(Icons.dashboard_outlined),
                        selectedIcon: const Icon(Icons.dashboard),
                        label: tr(context, 'Dashboard'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.receipt_long_outlined),
                        selectedIcon: const Icon(Icons.receipt_long),
                        label: tr(context, 'Orders'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.people_outline),
                        selectedIcon: const Icon(Icons.people),
                        label: tr(context, 'Customers'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.design_services_outlined),
                        selectedIcon: const Icon(Icons.design_services),
                        label: tr(context, 'Templates'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.store_outlined),
                        selectedIcon: const Icon(Icons.store),
                        label: tr(context, 'Shop'),
                      ),
                    ]
                  : [
                      NavigationDestination(
                        icon: const Icon(Icons.dashboard_outlined),
                        selectedIcon: const Icon(Icons.dashboard),
                        label: tr(context, 'Dashboard'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.receipt_long_outlined),
                        selectedIcon: const Icon(Icons.receipt_long),
                        label: tr(context, 'Orders'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.people_outline),
                        selectedIcon: const Icon(Icons.people),
                        label: tr(context, 'Customers'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.groups_outlined),
                        selectedIcon: const Icon(Icons.groups),
                        label: tr(context, 'Workers'),
                      ),
                    ],
            ),
    );
  }

  Color _sessionBackground(ShopWorker? worker) {
    if (worker == null) return _surface;
    if (worker.roles.contains('manager')) return const Color(0xFFEAF4FF);
    if (worker.roles.contains('accountant')) return const Color(0xFFEAF8EF);
    if (worker.roles.contains('cutter')) return const Color(0xFFFFF6E1);
    return const Color(0xFFFFF0E8);
  }

  Future<void> _openOrder(BuildContext context, {TailorOrder? order}) async {
    final result = await Navigator.of(context).push<TailorOrder>(
      MaterialPageRoute(
        builder: (_) => CreateOrderPage(
          profile: profile,
          customers: customers,
          orders: orders,
          templates: templates,
          onCustomerSaved: onCustomerSaved,
          existing: order,
        ),
      ),
    );
    if (result != null) onOrderSaved(result);
  }

  Future<void> _openCustomer(BuildContext context,
      {TailorCustomer? customer}) async {
    final result = await showDialog<TailorCustomer>(
      context: context,
      builder: (_) => CustomerDialog(customer: customer),
    );
    if (result != null) onCustomerSaved(result);
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile(this.icon, this.label, this.index, this.tab, this.onTap);

  final IconData icon;
  final String label;
  final int index;
  final int tab;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: index == tab,
      leading: Icon(icon),
      title: Text(tr(context, label)),
      onTap: () {
        Navigator.of(context).pop();
        onTap(index);
      },
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher();

  @override
  Widget build(BuildContext context) {
    final scope = AppLanguageScope.of(context);
    final isRight = scope.language == AppLanguage.mr;
    final label = isRight ? 'ENG' : 'MAR';
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tr(context, 'Language'),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => scope.onChanged(
            isRight ? AppLanguage.en : AppLanguage.mr,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 72,
            height: 34,
            padding: const EdgeInsets.all(4),
            alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE8EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFC8D6DB)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment:
                      isRight ? Alignment.centerLeft : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF405866),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment:
                      isRight ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({
    super.key,
    required this.profile,
    required this.customers,
    required this.orders,
    required this.workers,
    required this.onNewOrder,
    required this.onAddCustomer,
    required this.onOrderSaved,
    required this.onTemplateAssigned,
  });

  final ShopProfile profile;
  final List<TailorCustomer> customers;
  final List<TailorOrder> orders;
  final List<ShopWorker> workers;
  final VoidCallback onNewOrder;
  final VoidCallback onAddCustomer;
  final ValueChanged<TailorOrder> onOrderSaved;
  final void Function({
    required String orderId,
    required int itemIndex,
    required int unitIndex,
    required ShopWorker worker,
    String? status,
  }) onTemplateAssigned;

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((order) => order.status != 'Delivered').length;
    final revenue = orders.fold<int>(0, (sum, order) => sum + order.amount);
    final load = (pending / profile.maxOrdersPerDay).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroPanel(profile: profile, load: load),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onNewOrder,
                icon: const Icon(Icons.add),
                label: Text(tr(context, 'New Order')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAddCustomer,
                icon: const Icon(Icons.person_add_alt),
                label: Text(tr(context, 'Add Customer')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MetricGrid(
          items: [
            _MetricData(tr(context, 'All Orders'), '${orders.length}',
                Icons.receipt_long),
            _MetricData(tr(context, 'Pending'), '$pending', Icons.timelapse),
            _MetricData(
                tr(context, 'Customers'), '${customers.length}', Icons.people),
            _MetricData(
                tr(context, 'Revenue'), 'Rs $revenue', Icons.payments_outlined),
          ],
        ),
        const SizedBox(height: 14),
        const _SectionHeader(title: 'Recent Orders', action: 'View all'),
        const SizedBox(height: 8),
        _RecentOrderCards(
          orders: orders,
          workers: workers,
          limit: 3,
          onOrderSaved: onOrderSaved,
          onTemplateAssigned: onTemplateAssigned,
        ),
        const SizedBox(height: 14),
        const _SectionHeader(title: 'Recent Customers', action: 'Quick Add'),
        const SizedBox(height: 8),
        for (final customer in customers.take(3))
          CustomerCard(
            customer: customer,
            orders: orders
                .where((order) => order.customerName == customer.name)
                .toList(),
          ),
      ],
    );
  }
}

class ManagerDashboardTab extends StatelessWidget {
  const ManagerDashboardTab({
    super.key,
    required this.orders,
    required this.workers,
    required this.onOrderSaved,
    required this.onTemplateAssigned,
  });

  final List<TailorOrder> orders;
  final List<ShopWorker> workers;
  final ValueChanged<TailorOrder> onOrderSaved;
  final void Function({
    required String orderId,
    required int itemIndex,
    required int unitIndex,
    required ShopWorker worker,
    String? status,
  }) onTemplateAssigned;

  @override
  Widget build(BuildContext context) {
    final activeOrders = orders
        .where((order) => order.status != 'Delivered')
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final newOrders =
        orders.where((order) => order.status == 'Measurements').length;
    final readyOrders = orders
        .where(
            (order) => order.status != 'Delivered' && order.allTemplatesReady)
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(
          items: [
            _MetricData(tr(context, 'Total new orders'), '$newOrders',
                Icons.fiber_new_outlined),
            _MetricData(tr(context, 'Total ready orders'), '$readyOrders',
                Icons.task_alt_outlined),
          ],
        ),
        const SizedBox(height: 14),
        const _SectionHeader(title: 'Recent Orders', action: 'Closest first'),
        const SizedBox(height: 8),
        if (activeOrders.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders found',
            subtitle: 'Use the top-right New Order button to start a job.',
          )
        else
          _RecentOrderCards(
            orders: activeOrders,
            workers: workers,
            limit: 8,
            onOrderSaved: onOrderSaved,
            onTemplateAssigned: onTemplateAssigned,
          ),
      ],
    );
  }
}

class _RecentOrderCards extends StatelessWidget {
  const _RecentOrderCards({
    required this.orders,
    required this.workers,
    required this.limit,
    required this.onOrderSaved,
    required this.onTemplateAssigned,
  });

  final List<TailorOrder> orders;
  final List<ShopWorker> workers;
  final int limit;
  final ValueChanged<TailorOrder> onOrderSaved;
  final void Function({
    required String orderId,
    required int itemIndex,
    required int unitIndex,
    required ShopWorker worker,
    String? status,
  }) onTemplateAssigned;

  @override
  Widget build(BuildContext context) {
    final entries = _shopOrderEntriesFor(orders).take(limit).toList();
    if (entries.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders found',
        subtitle: 'Use the top-right New Order button to start a job.',
      );
    }
    return Column(
      children: [
        for (final entry in entries)
          if (entry.readyOrder != null)
            _ReadyToDeliverOrderCard(
              order: entry.readyOrder!,
              onTap: () => _openOrderDetails(context, entry.readyOrder!),
            )
          else
            _OrderTemplateWorkCard(
              data: entry.templateCard!,
              workerName: _workerNameFor(
                  workers, entry.templateCard!.assignedWorkerMobile),
              onTap: () => _openAssignment(context, entry.templateCard!),
            ),
      ],
    );
  }

  Future<void> _openAssignment(
    BuildContext context,
    _OrderTemplateCardData card,
  ) async {
    final result = await showDialog<_TemplateAssignmentResult>(
      context: context,
      builder: (_) => _TemplateAssignmentDialog(
        data: card,
        workers: workers,
        assignedWorkerName: _workerNameFor(workers, card.assignedWorkerMobile),
      ),
    );
    if (result == null) return;
    onTemplateAssigned(
      orderId: card.order.id,
      itemIndex: card.itemIndex,
      unitIndex: card.unitIndex,
      worker: result.worker,
      status: result.status,
    );
  }

  Future<void> _openOrderDetails(
    BuildContext context,
    TailorOrder order,
  ) async {
    final updated = await showDialog<TailorOrder>(
      context: context,
      builder: (_) => OrderDetailsDialog(order: order),
    );
    if (updated != null) onOrderSaved(updated);
  }
}

class WorkerTaskDashboardTab extends StatelessWidget {
  const WorkerTaskDashboardTab({
    super.key,
    required this.worker,
    required this.orders,
    required this.onTemplateReady,
  });

  final ShopWorker worker;
  final List<TailorOrder> orders;
  final void Function({
    required String orderId,
    required int itemIndex,
    required int unitIndex,
    required ShopWorker worker,
    String? status,
  }) onTemplateReady;

  @override
  Widget build(BuildContext context) {
    final tasks = _assignedTasks()
      ..sort((a, b) => a.order.dueDate.compareTo(b.order.dueDate));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(
          items: [
            _MetricData(tr(context, 'Total assigned templates'),
                '${tasks.length}', Icons.assignment_ind_outlined),
            _MetricData(tr(context, 'Total wallet balance'),
                'Rs ${worker.walletBalance}', Icons.account_balance_wallet),
          ],
        ),
        const SizedBox(height: 14),
        const _SectionHeader(title: 'Assigned Templates', action: 'Due first'),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const _EmptyState(
            icon: Icons.assignment_turned_in_outlined,
            title: 'No assigned templates',
            subtitle: 'Assigned work will appear here.',
          )
        else
          for (final task in tasks)
            _WorkerAssignedTemplateCard(
              task: task,
              onTap: () => _openTask(context, task),
            ),
      ],
    );
  }

  List<_WorkerAssignedTemplateTask> _assignedTasks() {
    final tasks = <_WorkerAssignedTemplateTask>[];
    for (final order in orders) {
      if (order.status == 'Delivered') continue;
      for (var itemIndex = 0; itemIndex < order.items.length; itemIndex++) {
        final item = order.items[itemIndex];
        for (final entry in item.assignedWorkerByUnit.entries) {
          if (entry.value == worker.mobile) {
            tasks.add(
              _WorkerAssignedTemplateTask(
                order: order,
                item: item,
                itemIndex: itemIndex,
                unitIndex: entry.key,
              ),
            );
          }
        }
      }
    }
    return tasks;
  }

  Future<void> _openTask(
    BuildContext context,
    _WorkerAssignedTemplateTask task,
  ) async {
    final markReady = await showDialog<bool>(
      context: context,
      builder: (_) => _WorkerTaskDialog(task: task),
    );
    if (markReady != true) return;
    onTemplateReady(
      orderId: task.order.id,
      itemIndex: task.itemIndex,
      unitIndex: task.unitIndex,
      worker: worker,
      status: 'Ready',
    );
  }
}

class _WorkerAssignedTemplateTask {
  const _WorkerAssignedTemplateTask({
    required this.order,
    required this.item,
    required this.itemIndex,
    required this.unitIndex,
  });

  final TailorOrder order;
  final OrderTemplateItem item;
  final int itemIndex;
  final int unitIndex;
}

class _WorkerAssignedTemplateCard extends StatelessWidget {
  const _WorkerAssignedTemplateCard({
    required this.task,
    required this.onTap,
  });

  final _WorkerAssignedTemplateTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _templateStatusColors(task.item.status);
    final measurementText = task.item.measurements.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.$1.withValues(alpha: 0.75), colors.$2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.$3),
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  SizedBox(
                    width: 62,
                    child: Text(
                      _formatDate(task.order.dueDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${task.item.templateName} ${task.unitIndex + 1}/${task.item.quantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          measurementText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr(context, _shortStatus(task.item.status)),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerTaskDialog extends StatelessWidget {
  const _WorkerTaskDialog({required this.task});

  final _WorkerAssignedTemplateTask task;

  @override
  Widget build(BuildContext context) {
    final isReady = task.item.status == 'Ready';
    return AlertDialog(
      title: Text(task.item.templateName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssignmentLine('Customer', task.order.customerName),
          _AssignmentLine('Due date', _formatDate(task.order.dueDate)),
          _AssignmentLine('Status', tr(context, task.item.status)),
          const SizedBox(height: 12),
          Text(
            tr(context, 'Measurements'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in task.item.measurements.entries)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${entry.key}: ${entry.value}'),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: isReady ? null : () => Navigator.of(context).pop(true),
          child: Text(tr(context, 'Ready')),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.profile, required this.load});

  final ShopProfile profile;
  final double load;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _brandDark,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.shopName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context,
                  'Shop floor is at 90% load. Delivery might be tight.'),
              style: const TextStyle(color: Color(0xFFFFEAD2)),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: load,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: _accent,
              backgroundColor: Colors.white24,
            ),
            const SizedBox(height: 8),
            Text(
              '${(load * 100).round()}% ${tr(context, 'of daily capacity used')}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersTab extends StatefulWidget {
  const OrdersTab({
    super.key,
    required this.orders,
    required this.workers,
    required this.onEditOrder,
    required this.onOrderSaved,
    required this.onTemplateAssigned,
  });

  final List<TailorOrder> orders;
  final List<ShopWorker> workers;
  final ValueChanged<TailorOrder> onEditOrder;
  final ValueChanged<TailorOrder> onOrderSaved;
  final void Function({
    required String orderId,
    required int itemIndex,
    required int unitIndex,
    required ShopWorker worker,
    String? status,
  }) onTemplateAssigned;

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final entries = _shopOrderEntries.where((entry) {
      final text = entry.searchText.toLowerCase();
      return text.contains(_query.toLowerCase());
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          inputFormatters: localizedTextInputFormatters(context),
          decoration: InputDecoration(
            hintText: tr(context, 'Search orders...'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders found',
            subtitle: 'Use the top-right New Order button to start a job.',
          )
        else
          for (final entry in entries)
            if (entry.readyOrder != null)
              _ReadyToDeliverOrderCard(
                order: entry.readyOrder!,
                onTap: () => _openOrderDetails(entry.readyOrder!),
              )
            else
              _OrderTemplateWorkCard(
                data: entry.templateCard!,
                workerName:
                    _workerName(entry.templateCard!.assignedWorkerMobile),
                onTap: () => _openAssignment(entry.templateCard!),
              ),
      ],
    );
  }

  List<_ShopOrderEntry> get _shopOrderEntries {
    return _shopOrderEntriesFor(widget.orders);
  }

  String? _workerName(String? mobile) {
    return _workerNameFor(widget.workers, mobile);
  }

  Future<void> _openAssignment(_OrderTemplateCardData card) async {
    final result = await showDialog<_TemplateAssignmentResult>(
      context: context,
      builder: (_) => _TemplateAssignmentDialog(
        data: card,
        workers: widget.workers,
        assignedWorkerName: _workerName(card.assignedWorkerMobile),
      ),
    );
    if (result == null) return;
    widget.onTemplateAssigned(
      orderId: card.order.id,
      itemIndex: card.itemIndex,
      unitIndex: card.unitIndex,
      worker: result.worker,
      status: result.status,
    );
  }

  Future<void> _openOrderDetails(TailorOrder order) async {
    final updated = await showDialog<TailorOrder>(
      context: context,
      builder: (_) => OrderDetailsDialog(order: order),
    );
    if (updated != null) widget.onOrderSaved(updated);
  }
}

List<_ShopOrderEntry> _shopOrderEntriesFor(List<TailorOrder> orders) {
  final entries = <_ShopOrderEntry>[];
  for (final order in orders) {
    if (order.status == 'Delivered') continue;
    if (order.allTemplatesReady) {
      entries.add(_ShopOrderEntry.ready(order));
      continue;
    }
    for (var itemIndex = 0; itemIndex < order.items.length; itemIndex++) {
      final item = order.items[itemIndex];
      for (var unitIndex = 0; unitIndex < item.quantity; unitIndex++) {
        entries.add(
          _ShopOrderEntry.template(
            _OrderTemplateCardData(
              order: order,
              item: item,
              itemIndex: itemIndex,
              unitIndex: unitIndex,
              assignedWorkerMobile: item.assignedWorkerByUnit[unitIndex],
            ),
          ),
        );
      }
    }
  }
  entries.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return entries;
}

String? _workerNameFor(List<ShopWorker> workers, String? mobile) {
  if (mobile == null) return null;
  for (final worker in workers) {
    if (worker.mobile == mobile) return worker.name;
  }
  return mobile;
}

class _ShopOrderEntry {
  const _ShopOrderEntry._({this.readyOrder, this.templateCard});

  factory _ShopOrderEntry.ready(TailorOrder order) {
    return _ShopOrderEntry._(readyOrder: order);
  }

  factory _ShopOrderEntry.template(_OrderTemplateCardData card) {
    return _ShopOrderEntry._(templateCard: card);
  }

  final TailorOrder? readyOrder;
  final _OrderTemplateCardData? templateCard;

  DateTime get dueDate => readyOrder?.dueDate ?? templateCard!.order.dueDate;

  String get searchText {
    final order = readyOrder ?? templateCard!.order;
    final template = templateCard?.item.templateName ?? order.summary;
    return '${order.customerName} $template ${order.id} ready deliver';
  }
}

class _OrderTemplateCardData {
  const _OrderTemplateCardData({
    required this.order,
    required this.item,
    required this.itemIndex,
    required this.unitIndex,
    required this.assignedWorkerMobile,
  });

  final TailorOrder order;
  final OrderTemplateItem item;
  final int itemIndex;
  final int unitIndex;
  final String? assignedWorkerMobile;
}

class _ReadyToDeliverOrderCard extends StatelessWidget {
  const _ReadyToDeliverOrderCard({
    required this.order,
    required this.onTap,
  });

  final TailorOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _templateStatusColors('Ready');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.$1.withValues(alpha: 0.78), colors.$2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.$3),
          boxShadow: [
            BoxShadow(
              color: colors.$3.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${_formatDate(order.dueDate)}  ${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      tr(context, 'All templates are ready to deliver'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.local_shipping_outlined,
                      size: 18, color: colors.$4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTemplateWorkCard extends StatelessWidget {
  const _OrderTemplateWorkCard({
    required this.data,
    required this.workerName,
    required this.onTap,
  });

  final _OrderTemplateCardData data;
  final String? workerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _templateStatusColors(data.item.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.$1.withValues(alpha: 0.72), colors.$2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.$3),
          boxShadow: [
            BoxShadow(
              color: colors.$3.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${_formatDate(data.order.dueDate)}  ${data.order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${data.item.templateName} ${data.unitIndex + 1}/${data.item.quantity}${workerName == null ? '' : ' - $workerName'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    workerName == null
                        ? Icons.assignment_ind_outlined
                        : Icons.verified_user_outlined,
                    size: 18,
                    color: colors.$4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateAssignmentDialog extends StatefulWidget {
  const _TemplateAssignmentDialog({
    required this.data,
    required this.workers,
    required this.assignedWorkerName,
  });

  final _OrderTemplateCardData data;
  final List<ShopWorker> workers;
  final String? assignedWorkerName;

  @override
  State<_TemplateAssignmentDialog> createState() =>
      _TemplateAssignmentDialogState();
}

class _TemplateAssignmentDialogState extends State<_TemplateAssignmentDialog> {
  String? _workerMobile;
  late String _status;

  @override
  void initState() {
    super.initState();
    _workerMobile = widget.data.assignedWorkerMobile ??
        (widget.workers.isEmpty ? null : widget.workers.first.mobile);
    _status = widget.data.assignedWorkerMobile == null
        ? 'In Stitching'
        : widget.data.item.status;
    if (!['In Stitching', 'Ready', 'Hold'].contains(_status)) {
      _status = 'In Stitching';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.item;
    return AlertDialog(
      title: Text('${item.templateName} ${tr(context, 'Assignment')}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AssignmentLine('Customer', widget.data.order.customerName),
            _AssignmentLine(
                'Order date', _formatDate(widget.data.order.orderDate)),
            _AssignmentLine('Due date', _formatDate(widget.data.order.dueDate)),
            _AssignmentLine('Status', tr(context, item.status)),
            if (widget.assignedWorkerName != null)
              _AssignmentLine('Assigned', widget.assignedWorkerName!),
            const SizedBox(height: 12),
            Text(
              tr(context, 'Measurements'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            if (item.measurements.isEmpty)
              Text(tr(context, 'No measurements captured.'))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in item.measurements.entries)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${entry.key}: ${entry.value}'),
                    ),
                ],
              ),
            const SizedBox(height: 14),
            if (widget.workers.isEmpty)
              Text(
                  tr(context, 'Create a worker in Shop before assigning work.'))
            else
              DropdownButtonFormField<String>(
                initialValue: _workerMobile,
                decoration:
                    InputDecoration(labelText: tr(context, 'Assign worker')),
                items: [
                  for (final worker in widget.workers)
                    DropdownMenuItem(
                      value: worker.mobile,
                      child: Text('${worker.name} - ${worker.speciality}'),
                    ),
                ],
                onChanged: (value) => setState(() => _workerMobile = value),
              ),
            if (widget.data.assignedWorkerMobile != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration:
                    InputDecoration(labelText: tr(context, 'Template status')),
                items: [
                  DropdownMenuItem(
                      value: 'In Stitching',
                      child: Text(tr(context, 'In Stitching'))),
                  DropdownMenuItem(
                      value: 'Ready', child: Text(tr(context, 'Ready'))),
                  DropdownMenuItem(
                      value: 'Hold', child: Text(tr(context, 'Hold'))),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'In Stitching'),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${tr(context, 'Maker payment')}: Rs ${item.makerCharges}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: _workerMobile == null ? null : _assign,
          child: Text(
            tr(context,
                widget.data.assignedWorkerMobile == null ? 'Assign' : 'Save'),
          ),
        ),
      ],
    );
  }

  void _assign() {
    final mobile = _workerMobile;
    if (mobile == null) return;
    final worker = widget.workers.firstWhere((item) => item.mobile == mobile);
    Navigator.of(context).pop(
      _TemplateAssignmentResult(
        worker: worker,
        status:
            widget.data.assignedWorkerMobile == null ? 'In Stitching' : _status,
      ),
    );
  }
}

class _TemplateAssignmentResult {
  const _TemplateAssignmentResult({
    required this.worker,
    required this.status,
  });

  final ShopWorker worker;
  final String status;
}

class _AssignmentLine extends StatelessWidget {
  const _AssignmentLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              tr(context, label),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomersTab extends StatefulWidget {
  const CustomersTab({
    super.key,
    required this.customers,
    required this.orders,
    required this.onAddCustomer,
    required this.onOrderSaved,
  });

  final List<TailorCustomer> customers;
  final List<TailorOrder> orders;
  final VoidCallback onAddCustomer;
  final ValueChanged<TailorOrder> onOrderSaved;

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.customers.where((customer) {
      final text = '${customer.name} ${customer.phone}'.toLowerCase();
      return text.contains(_query.toLowerCase());
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          inputFormatters: localizedTextInputFormatters(context),
          decoration: InputDecoration(
            hintText: tr(context, 'Search by name or phone...'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const _EmptyState(
            icon: Icons.people_outline,
            title: 'No customers found',
            subtitle: 'Tap + to add your first customer.',
          )
        else
          for (final customer in filtered)
            CustomerCard(
              customer: customer,
              orders: _ordersFor(customer),
              isReady: _allOrderedTemplatesReady(customer),
              onTap: () => _openCustomerHistory(customer),
            ),
      ],
    );
  }

  bool _allOrderedTemplatesReady(TailorCustomer customer) {
    final customerOrders = _ordersFor(customer);
    if (customerOrders.isEmpty) return false;
    return customerOrders.every((order) => order.allTemplatesReady);
  }

  List<TailorOrder> _ordersFor(TailorCustomer customer) {
    return widget.orders
        .where((order) => order.customerName == customer.name)
        .toList();
  }

  void _openCustomerHistory(TailorCustomer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerHistoryPage(
          customer: customer,
          orders: widget.orders
              .where((order) => order.customerName == customer.name)
              .toList(),
          onOrderSaved: widget.onOrderSaved,
        ),
      ),
    );
  }
}

class CustomerHistoryPage extends StatefulWidget {
  const CustomerHistoryPage({
    super.key,
    required this.customer,
    required this.orders,
    required this.onOrderSaved,
  });

  final TailorCustomer customer;
  final List<TailorOrder> orders;
  final ValueChanged<TailorOrder> onOrderSaved;

  @override
  State<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage> {
  late List<TailorOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = [...widget.orders];
  }

  @override
  Widget build(BuildContext context) {
    final inStitchingOrders =
        _orders.where((order) => order.status == 'In Stitching').length;
    final measurementOrders =
        _orders.where((order) => order.status == 'Measurements').length;
    final totalPaymentReceived =
        _orders.fold<int>(0, (sum, order) => sum + order.advancePayment);
    final totalBillAmount =
        _orders.fold<int>(0, (sum, order) => sum + order.amount);
    return Scaffold(
      appBar: AppBar(title: Text(widget.customer.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FrostedInfoCard(
                    color: const Color(0xCCDBECFF),
                    borderColor: const Color(0xFF8BBDF0),
                    children: [
                      Text(
                        widget.customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF123F70),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.customer.phone,
                        style: const TextStyle(
                          color: Color(0xFF174A7C),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.customer.address.isEmpty
                            ? tr(context, 'No address')
                            : widget.customer.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF174A7C),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FrostedInfoCard(
                    color: const Color(0xCCE6F7E9),
                    borderColor: const Color(0xFF91D69C),
                    children: [
                      _SummaryLine(
                        label: 'In stitching',
                        value: inStitchingOrders.toString(),
                      ),
                      _SummaryLine(
                        label: 'Measurement',
                        value: measurementOrders.toString(),
                      ),
                      _SummaryLine(
                        label: 'Received',
                        value: 'Rs $totalPaymentReceived',
                      ),
                      _SummaryLine(
                        label: 'Bill',
                        value: 'Rs $totalBillAmount',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionHeader(title: 'Order History', action: 'Details'),
            const SizedBox(height: 10),
            if (_orders.isEmpty)
              const _EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders found',
                subtitle: 'This customer has no order history yet.',
              )
            else
              for (final order in _orders)
                _CustomerOrderHistoryCard(
                  order: order,
                  onTap: () => _openOrderDetails(order),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOrderDetails(TailorOrder order) async {
    final updated = await showDialog<TailorOrder>(
      context: context,
      builder: (_) => OrderDetailsDialog(order: order),
    );
    if (updated == null) return;
    setState(() {
      final index = _orders.indexWhere((item) => item.id == updated.id);
      if (index >= 0) _orders[index] = updated;
    });
    widget.onOrderSaved(updated);
  }
}

class _FrostedInfoCard extends StatelessWidget {
  const _FrostedInfoCard({
    required this.color,
    required this.borderColor,
    required this.children,
  });

  final Color color;
  final Color borderColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tr(context, label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF165C2E),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F4D25),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerOrderHistoryCard extends StatelessWidget {
  const _CustomerOrderHistoryCard({required this.order, required this.onTap});

  final TailorOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (order.status) {
      'Delivered' => const Color(0xFFE6F7EA),
      'In Stitching' => const Color(0xFFFFF4CC),
      _ => const Color(0xFFEAF6FF),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: _CompactOrderField(
                      label: 'Ord', value: _formatShortDate(order.orderDate)),
                ),
                Expanded(
                  child: _CompactOrderField(
                      label: 'Due', value: _formatShortDate(order.dueDate)),
                ),
                Expanded(
                  child: _CompactOrderField(
                      label: 'Status',
                      value: tr(context, _shortStatus(order.status))),
                ),
                Expanded(
                  child: _CompactOrderField(
                      label: 'Paid', value: 'Rs${order.advancePayment}'),
                ),
                Expanded(
                  child: _CompactOrderField(
                      label: 'Bal', value: 'Rs${order.balanceAmount}'),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactOrderField extends StatelessWidget {
  const _CompactOrderField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.black54,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class OrderDetailsDialog extends StatefulWidget {
  const OrderDetailsDialog({super.key, required this.order});

  final TailorOrder order;

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  late final TextEditingController _newPayment;
  late final TextEditingController _promiseNote;
  late String _paymentMode;
  late String _status;
  late List<OrderTemplateItem> _items;
  late List<OrderPayment> _payments;
  DateTime? _promiseDate;

  @override
  void initState() {
    super.initState();
    _newPayment = TextEditingController(text: '0');
    _promiseNote = TextEditingController();
    _paymentMode = widget.order.paymentMode;
    _status = widget.order.status;
    _payments = _sortPayments(widget.order.payments);
    _items = [
      for (final item in widget.order.items)
        OrderTemplateItem(
          templateName: item.templateName,
          quantity: item.quantity,
          status: item.status,
          charges: item.charges,
          makerCharges: item.makerCharges,
          measurementUpdatedAt: item.measurementUpdatedAt,
          measurements: Map.of(item.measurements),
          assignedWorkerByUnit: Map.of(item.assignedWorkerByUnit),
          workerPaymentStatusByUnit: Map.of(item.workerPaymentStatusByUnit),
        ),
    ];
  }

  @override
  void dispose() {
    _newPayment.dispose();
    _promiseNote.dispose();
    super.dispose();
  }

  int get _existingPaid => widget.order.advancePayment;

  int get _incomingPayment => int.tryParse(_newPayment.text.trim()) ?? 0;

  int get _paid => (_existingPaid + _incomingPayment).clamp(0, _total).toInt();

  int get _total => widget.order.amount;

  int get _balance => (_total - _paid.clamp(0, _total)).toInt();

  bool get _allTemplatesReady => _items.every((item) => item.status == 'Ready');

  bool get _canDeliver => _allTemplatesReady && _balance == 0;

  bool get _hasPromiseNote => _promiseNote.text.trim().isNotEmpty;

  bool get _isReadOnly => widget.order.status == 'Delivered';

  @override
  Widget build(BuildContext context) {
    final surface = _orderDetailsSurfaceColors();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [surface.$1, surface.$2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: surface.$3),
          boxShadow: [
            BoxShadow(
              color: surface.$3.withValues(alpha: 0.26),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tr(context, 'Order')} ${widget.order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                    ),
                  ),
                  _BalanceBadge(balance: _balance),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              _OrderDetailRow(
                label: 'Order',
                value: _formatDate(widget.order.orderDate),
                secondLabel: 'Due',
                secondValue: _formatDate(widget.order.dueDate),
              ),
              _OrderDetailRow(
                label: 'Weight',
                value: '${widget.order.weightKg.toStringAsFixed(2)} kg',
                secondLabel: 'Total',
                secondValue: 'Rs $_total',
              ),
              const SizedBox(height: 6),
              const _MiniSectionTitle('Templates'),
              const SizedBox(height: 4),
              _OrderTemplatesTable(
                orderId: widget.order.id,
                items: _items,
              ),
              const SizedBox(height: 4),
              const _MiniSectionTitle('Payment'),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 82,
                    child: SizedBox(
                      height: 40,
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentMode,
                        isDense: true,
                        decoration: _compactDecoration(context, 'Mode'),
                        style: const TextStyle(fontSize: 12, color: _ink),
                        items: const [
                          DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Card', child: Text('Card')),
                        ],
                        onChanged: _isReadOnly
                            ? null
                            : (value) =>
                                setState(() => _paymentMode = value ?? 'UPI'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _newPayment,
                        keyboardType: TextInputType.number,
                        enabled: !_isReadOnly,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(fontSize: 12),
                        decoration: _compactDecoration(
                          context,
                          'Paying amount',
                          alwaysFloatLabel: true,
                        ),
                        onChanged: _isReadOnly ? null : (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _promiseNote,
                        enabled: !_isReadOnly,
                        inputFormatters: localizedTextInputFormatters(context),
                        style: const TextStyle(fontSize: 12),
                        decoration: _compactDecoration(context, 'Promise note'),
                        onChanged: _isReadOnly ? null : (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 104,
                    height: 40,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _isReadOnly ? null : _pickPromiseDate,
                      child: InputDecorator(
                        decoration: _compactDecoration(context, 'Promise date'),
                        child: Text(
                          _promiseDate == null
                              ? tr(context, 'Date')
                              : _formatShortDate(_promiseDate!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _OrderDetailRow(
                label: 'Paid',
                value: 'Rs $_paid',
                secondLabel: 'Balance',
                secondValue: 'Rs $_balance',
              ),
              const SizedBox(height: 4),
              const _MiniSectionTitle('Payment History'),
              const SizedBox(height: 3),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEBD8C4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      for (final payment in _visiblePayments)
                        _PaymentHistoryLine(
                          payment: payment,
                          pending: (_incomingPayment > 0 &&
                                  payment.amount ==
                                      _incomingPayment
                                          .clamp(0, _total)
                                          .toInt() &&
                                  payment.mode == _paymentMode) ||
                              (_hasPromiseNote &&
                                  payment.note == _promiseNote.text.trim()),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 176,
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    isDense: true,
                    isExpanded: true,
                    decoration: _compactDecoration(context, 'Status'),
                    style: const TextStyle(fontSize: 12, color: _ink),
                    items: [
                      DropdownMenuItem(
                          value: 'Measurements',
                          child: Text(tr(context, 'Measurements'))),
                      DropdownMenuItem(
                          value: 'In Stitching',
                          child: Text(tr(context, 'In Stitching'))),
                      DropdownMenuItem(
                          value: 'Ready', child: Text(tr(context, 'Ready'))),
                      DropdownMenuItem(
                          value: 'Delivered',
                          child: Text(tr(context, 'Delivered'))),
                      const DropdownMenuItem(value: 'DWP', child: Text('DWP')),
                    ],
                    onChanged: _isReadOnly
                        ? null
                        : (value) {
                            if (value == null) return;
                            if (value == 'Delivered' && !_canDeliver) return;
                            setState(() => _status = value);
                          },
                  ),
                ),
              ),
              if (!_isReadOnly && !_canDeliver) ...[
                const SizedBox(height: 4),
                Text(
                  tr(context,
                      'Deliver when templates are Ready and balance is Rs 0, or add a promise note for DWP.'),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 8),
              if (_isReadOnly)
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr(context, 'Close')),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (_canDeliver || _hasPromiseNote)
                            ? () {
                                setState(() {
                                  _status =
                                      _hasPromiseNote ? 'DWP' : 'Delivered';
                                });
                                _save(usePromiseNote: _hasPromiseNote);
                              }
                            : null,
                        child: Text(tr(context, 'Delivered')),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: Text(tr(context, 'Save')),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  (
    Color,
    Color,
    Color,
  ) _orderDetailsSurfaceColors() {
    return switch (_status) {
      'Delivered' => (
          const Color(0xFFEAFBEF).withValues(alpha: 0.96),
          const Color(0xFFD7F5DF).withValues(alpha: 0.92),
          const Color(0xFF9DD8AA),
        ),
      'In Stitching' => (
          const Color(0xFFFFF8DD).withValues(alpha: 0.97),
          const Color(0xFFFFEDB8).withValues(alpha: 0.92),
          const Color(0xFFE8CB75),
        ),
      'DWP' => (
          const Color(0xFFFFEFEF).withValues(alpha: 0.97),
          const Color(0xFFFFD9D9).withValues(alpha: 0.92),
          const Color(0xFFE9A0A0),
        ),
      _ => (
          const Color(0xFFEAF6FF).withValues(alpha: 0.97),
          const Color(0xFFD7ECFF).withValues(alpha: 0.92),
          const Color(0xFF9ECDF5),
        ),
    };
  }

  InputDecoration _compactDecoration(
    BuildContext context,
    String label, {
    String? hint,
    bool alwaysFloatLabel = false,
  }) {
    return InputDecoration(
      labelText: tr(context, label),
      hintText: hint,
      floatingLabelBehavior:
          alwaysFloatLabel ? FloatingLabelBehavior.always : null,
      isDense: true,
      constraints: const BoxConstraints.tightFor(height: 40),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  void _save({bool usePromiseNote = false}) {
    final newPaymentAmount =
        _incomingPayment.clamp(0, _total - _existingPaid).toInt();
    final promiseNote = localizedInputText(context, _promiseNote.text).trim();
    final payments = _sortPayments([
      ..._payments,
      if (newPaymentAmount > 0)
        OrderPayment(
          amount: newPaymentAmount,
          mode: _paymentMode,
          paidAt: DateTime.now(),
        ),
      if (usePromiseNote && promiseNote.isNotEmpty)
        OrderPayment(
          amount: 0,
          mode: 'Promise',
          paidAt: DateTime.now(),
          note: promiseNote,
          promiseDate: _promiseDate,
        ),
    ]);
    Navigator.of(context).pop(
      widget.order.copyWith(
        status: _status,
        paymentMode: _paymentMode,
        advancePayment:
            (_existingPaid + newPaymentAmount).clamp(0, _total).toInt(),
        payments: payments,
        items: _items,
      ),
    );
  }

  List<OrderPayment> get _visiblePayments {
    return _sortPayments([
      ..._payments,
      if (_incomingPayment > 0)
        OrderPayment(
          amount: _incomingPayment.clamp(0, _total).toInt(),
          mode: _paymentMode,
          paidAt: DateTime.now(),
        ),
      if (_hasPromiseNote)
        OrderPayment(
          amount: 0,
          mode: 'Promise',
          paidAt: DateTime.now(),
          note: _promiseNote.text.trim(),
          promiseDate: _promiseDate,
        ),
    ]);
  }

  List<OrderPayment> _sortPayments(List<OrderPayment> payments) {
    return [...payments]..sort((a, b) => b.paidAt.compareTo(a.paidAt));
  }

  Future<void> _pickPromiseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _promiseDate ?? widget.order.dueDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _promiseDate = picked);
  }
}

class _BalanceBadge extends StatelessWidget {
  const _BalanceBadge({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final hasBalance = balance > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasBalance
            ? const Color(0xFFFFE3E3).withValues(alpha: 0.9)
            : const Color(0xFFDDF7E4).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasBalance ? const Color(0xFFD33D3D) : const Color(0xFF37A35C),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          hasBalance
              ? '${tr(context, 'Bal')} Rs $balance'
              : '${tr(context, 'Bal')} NIL',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                hasBalance ? const Color(0xFFB00020) : const Color(0xFF176B32),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _OrderDetailRow extends StatelessWidget {
  const _OrderDetailRow({
    required this.label,
    required this.value,
    required this.secondLabel,
    required this.secondValue,
  });

  final String label;
  final String value;
  final String secondLabel;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: _OrderDetailPair(label: label, value: value)),
          const SizedBox(width: 8),
          Expanded(
            child: _OrderDetailPair(label: secondLabel, value: secondValue),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailPair extends StatelessWidget {
  const _OrderDetailPair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${tr(context, label)}: ',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _MiniSectionTitle extends StatelessWidget {
  const _MiniSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      tr(context, label),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
    );
  }
}

class _OrderTemplatesTable extends StatelessWidget {
  const _OrderTemplatesTable({
    required this.orderId,
    required this.items,
  });

  final String orderId;
  final List<OrderTemplateItem> items;

  @override
  Widget build(BuildContext context) {
    final rows = <_OrderTemplateVisibleRow>[];
    var serial = 1;
    for (final item in items) {
      for (var unit = 0; unit < item.quantity; unit++) {
        rows.add(
          _OrderTemplateVisibleRow(
            id: '$orderId-$serial',
            templateName: item.templateName,
            rate: item.rate,
            status: item.status,
          ),
        );
        serial++;
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEBD8C4)),
      ),
      child: Column(
        children: [
          const _OrderTemplateTableRow(
            id: 'Template ID',
            template: 'Template',
            rate: 'Rate',
            status: 'Status',
            isHeader: true,
          ),
          for (final row in rows)
            _OrderTemplateTableRow(
              id: row.id,
              template: row.templateName,
              rate: 'Rs ${row.rate}',
              status: tr(context, _shortStatus(row.status)),
            ),
        ],
      ),
    );
  }
}

class _OrderTemplateVisibleRow {
  const _OrderTemplateVisibleRow({
    required this.id,
    required this.templateName,
    required this.rate,
    required this.status,
  });

  final String id;
  final String templateName;
  final int rate;
  final String status;
}

class _OrderTemplateTableRow extends StatelessWidget {
  const _OrderTemplateTableRow({
    required this.id,
    required this.template,
    required this.rate,
    required this.status,
    this.isHeader = false,
  });

  final String id;
  final String template;
  final String rate;
  final String status;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isHeader ? 10 : 9,
      fontWeight: isHeader ? FontWeight.w900 : FontWeight.w800,
      color: isHeader ? _brandDark : _ink,
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFEFF8FF) : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEBD8C4)),
        ),
      ),
      child: Row(
        children: [
          _OrderTemplateCell(
            text: isHeader ? tr(context, id) : id,
            flex: 3,
            style: style,
          ),
          _OrderTemplateCell(
            text: isHeader ? tr(context, template) : template,
            flex: 3,
            style: style,
          ),
          _OrderTemplateCell(
            text: isHeader ? tr(context, rate) : rate,
            flex: 2,
            style: style,
          ),
          _OrderTemplateCell(
            text: isHeader ? tr(context, status) : status,
            flex: 2,
            style: style,
          ),
        ],
      ),
    );
  }
}

class _OrderTemplateCell extends StatelessWidget {
  const _OrderTemplateCell({
    required this.text,
    required this.flex,
    required this.style,
  });

  final String text;
  final int flex;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}

class _PaymentHistoryLine extends StatelessWidget {
  const _PaymentHistoryLine({required this.payment, this.pending = false});

  final OrderPayment payment;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final note = payment.note?.trim();
    final promiseText = payment.promiseDate == null
        ? ''
        : ' (${_formatShortDate(payment.promiseDate!)})';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_formatShortDate(payment.paidAt)} ${payment.mode}${pending ? ' (new)' : ''}$promiseText${note == null || note.isEmpty ? '' : ' - $note'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Text(
            payment.amount == 0 && note != null && note.isNotEmpty
                ? 'DWP'
                : 'Rs ${payment.amount}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class TemplatesTab extends StatelessWidget {
  const TemplatesTab({
    super.key,
    required this.templates,
    required this.onSave,
    required this.onDelete,
  });

  final List<GarmentTemplate> templates;
  final ValueChanged<GarmentTemplate> onSave;
  final ValueChanged<GarmentTemplate> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          tr(context, 'Your custom garment templates'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _openTemplate(context),
          icon: const Icon(Icons.add),
          label: Text(tr(context, 'Create Template')),
        ),
        const SizedBox(height: 12),
        if (templates.isEmpty)
          const _EmptyState(
            icon: Icons.design_services_outlined,
            title: 'No templates yet',
            subtitle: 'Tap the + button to create your first garment template.',
          )
        else
          for (final template in templates)
            Card(
              child: ListTile(
                leading: const Icon(Icons.checkroom_outlined),
                title: Text(template.name),
                subtitle: Text(
                  '${tr(context, 'Charges')}: Rs ${template.charges} | ${tr(context, 'Maker charges')}: Rs ${template.makerCharges} | Rate: Rs ${template.rate}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openTemplate(context, template: template);
                    }
                    if (value == 'delete') onDelete(template);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'edit',
                        child: Text(tr(context, 'Edit Template'))),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text(tr(context, 'Delete Template'))),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _openTemplate(BuildContext context,
      {GarmentTemplate? template}) async {
    final result = await showDialog<GarmentTemplate>(
      context: context,
      builder: (_) => TemplateDialog(template: template),
    );
    if (result != null) onSave(result);
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.profile,
    required this.templates,
    required this.workers,
    required this.showSettings,
    required this.onTemplateSaved,
    required this.onTemplateDeleted,
    required this.onWorkerSaved,
    required this.onWorkerPaymentRecorded,
  });

  final ShopProfile profile;
  final List<GarmentTemplate> templates;
  final List<ShopWorker> workers;
  final bool showSettings;
  final ValueChanged<GarmentTemplate> onTemplateSaved;
  final ValueChanged<GarmentTemplate> onTemplateDeleted;
  final ValueChanged<ShopWorker> onWorkerSaved;
  final void Function({
    required ShopWorker worker,
    required int amount,
  }) onWorkerPaymentRecorded;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const List<String> _roles = [
    'manager',
    'cutter',
    'maker',
    'accountant',
  ];
  static const List<String> _specialities = [
    'cutting',
    'shirt-maker',
    'pant-maker',
    'all',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: widget.showSettings
          ? [
              _ShopSettingsHeader(profile: widget.profile),
              const SizedBox(height: 16),
              _TemplatesTableCard(
                templates: widget.templates,
                onSave: widget.onTemplateSaved,
                onDelete: widget.onTemplateDeleted,
              ),
            ]
          : [
              _WorkersTableCard(
                workers: widget.workers,
                onAdd: _openCreateWorker,
                onWorkerTap: _openWorkerPayments,
              ),
            ],
    );
  }

  Future<void> _openCreateWorker() async {
    final worker = await showDialog<ShopWorker>(
      context: context,
      builder: (_) => const _WorkerDialog(
        roles: _roles,
        specialities: _specialities,
      ),
    );
    if (worker == null) return;
    widget.onWorkerSaved(worker);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${worker.name} ${tr(context, 'created. Username')}: ${worker.mobile}',
        ),
      ),
    );
  }

  Future<void> _openWorkerPayments(ShopWorker worker) async {
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => _WorkerPaymentDialog(worker: worker),
    );
    if (amount == null) return;
    widget.onWorkerPaymentRecorded(worker: worker, amount: amount);
  }
}

class _WorkerDialog extends StatefulWidget {
  const _WorkerDialog({
    required this.roles,
    required this.specialities,
  });

  final List<String> roles;
  final List<String> specialities;

  @override
  State<_WorkerDialog> createState() => _WorkerDialogState();
}

class _WorkerDialogState extends State<_WorkerDialog> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final Set<String> _selectedRoles = {'maker'};
  String _speciality = 'all';

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr(context, 'Create Worker')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              inputFormatters: localizedTextInputFormatters(context),
              decoration: InputDecoration(
                labelText: tr(context, 'Worker Name'),
                prefixIcon: const Icon(Icons.person_add_alt_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: tr(context, 'Mobile Number'),
                prefixIcon: const Icon(Icons.phone_android_outlined),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _speciality,
              decoration: InputDecoration(
                labelText: tr(context, 'Speciality'),
                prefixIcon: const Icon(Icons.content_cut_outlined),
              ),
              items: [
                for (final speciality in widget.specialities)
                  DropdownMenuItem(
                    value: speciality,
                    child: Text(tr(context, speciality)),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _speciality = value ?? 'all'),
            ),
            const SizedBox(height: 12),
            Text(tr(context, 'Assign Roles'),
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final role in widget.roles)
                  FilterChip(
                    label: Text(tr(context, role)),
                    selected: _selectedRoles.contains(role),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRoles.add(role);
                        } else {
                          _selectedRoles.remove(role);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: _createWorker,
          child: Text(tr(context, 'Create')),
        ),
      ],
    );
  }

  void _createWorker() {
    final name = localizedInputText(context, _name.text).trim();
    final mobile = _mobile.text.trim();
    if (name.isEmpty || mobile.isEmpty || _selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'Enter worker details and select roles.')),
        ),
      );
      return;
    }
    final worker = ShopWorker(
      name: name,
      mobile: mobile,
      speciality: _speciality,
      roles: _selectedRoles.toList()..sort(),
      username: mobile,
      defaultPassword: _defaultWorkerPassword(name, mobile),
      password: _defaultWorkerPassword(name, mobile),
      mustResetPassword: true,
      walletBalance: 0,
    );
    Navigator.of(context).pop(worker);
  }
}

class _WorkerPaymentDialog extends StatefulWidget {
  const _WorkerPaymentDialog({required this.worker});

  final ShopWorker worker;

  @override
  State<_WorkerPaymentDialog> createState() => _WorkerPaymentDialogState();
}

class _WorkerPaymentDialogState extends State<_WorkerPaymentDialog> {
  final _amount = TextEditingController(text: '0');

  int get _withdrawAmount => int.tryParse(_amount.text.trim()) ?? 0;

  int get _nextBalance => widget.worker.walletBalance - _withdrawAmount;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = [...widget.worker.payments]
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return AlertDialog(
      title: Text('${widget.worker.name} ${tr(context, 'Payments')}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkerPaymentRow(
              label: 'Wallet balance',
              value: 'Rs ${widget.worker.walletBalance}',
              valueColor: widget.worker.walletBalance < 0
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF176B32),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr(context, 'Withdraw amount'),
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _WorkerPaymentRow(
              label: 'Balance after payment',
              value: 'Rs $_nextBalance',
              valueColor: _nextBalance < 0
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF176B32),
            ),
            const SizedBox(height: 14),
            Text(
              tr(context, 'Payment History'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            if (history.isEmpty)
              Text(tr(context, 'No worker payments recorded.'))
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEBD8C4)),
                ),
                child: Column(
                  children: [
                    for (final payment in history)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_formatShortDate(payment.paidAt)} ${payment.note}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            Text(
                              'Rs ${payment.amount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: _withdrawAmount <= 0
              ? null
              : () => Navigator.of(context).pop(_withdrawAmount),
          child: Text(tr(context, 'Update Payment')),
        ),
      ],
    );
  }
}

class _WorkerPaymentRow extends StatelessWidget {
  const _WorkerPaymentRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            tr(context, label),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ShopSettingsHeader extends StatelessWidget {
  const _ShopSettingsHeader({required this.profile});

  final ShopProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF8FF),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ShopInfoPanel(
                color: const Color(0xFFDFF0FF),
                borderColor: const Color(0xFF7FB6E8),
                children: [
                  Text(
                    profile.ownerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF064B77),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.phone,
                    style: const TextStyle(
                      color: Color(0xFF064B77),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ShopInfoPanel(
                color: const Color(0xFFE7F7E9),
                borderColor: const Color(0xFF8CCC96),
                children: [
                  Text(
                    profile.address,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Color(0xFF176B32),
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopInfoPanel extends StatelessWidget {
  const _ShopInfoPanel({
    required this.color,
    required this.borderColor,
    required this.children,
  });

  final Color color;
  final Color borderColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _TemplatesTableCard extends StatelessWidget {
  const _TemplatesTableCard({
    required this.templates,
    required this.onSave,
    required this.onDelete,
  });

  final List<GarmentTemplate> templates;
  final ValueChanged<GarmentTemplate> onSave;
  final ValueChanged<GarmentTemplate> onDelete;

  @override
  Widget build(BuildContext context) {
    final table = Column(
      children: [
        const _TemplateTableHeader(),
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(tr(context, 'No templates created')),
            ),
          )
        else
          for (final template in templates)
            _TemplateTableRow(
              template: template,
              onTap: () => _openTemplate(context, template: template),
            ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'Templates'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Material(
                  color: const Color(0xFF2E7DE0),
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: const Color(0xFF2E7DE0).withValues(alpha: 0.32),
                  child: IconButton(
                    tooltip: tr(context, 'Create Template'),
                    onPressed: () => _openTemplate(context),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEBD8C4)),
              ),
              child: table,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTemplate(
    BuildContext context, {
    GarmentTemplate? template,
  }) async {
    final result = await showDialog<GarmentTemplate>(
      context: context,
      builder: (_) => TemplateDialog(template: template),
    );
    if (result == null) return;
    if (template != null && result.name != template.name) {
      onDelete(template);
    }
    onSave(result);
  }
}

class _TemplateTableHeader extends StatelessWidget {
  const _TemplateTableHeader();

  @override
  Widget build(BuildContext context) {
    return const _TemplateTableCells(
      name: 'Template name',
      charges: 'Charges',
      makerCharges: 'Maker charges',
      fields: 'Custom fields',
      isHeader: true,
    );
  }
}

class _TemplateTableRow extends StatelessWidget {
  const _TemplateTableRow({
    required this.template,
    required this.onTap,
  });

  final GarmentTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: _TemplateTableCells(
        name: template.name,
        charges: 'Rs ${template.charges}',
        makerCharges: 'Rs ${template.makerCharges}',
        fields: template.fields.join(', '),
      ),
    );
  }
}

class _TemplateTableCells extends StatelessWidget {
  const _TemplateTableCells({
    required this.name,
    required this.charges,
    required this.makerCharges,
    required this.fields,
    this.isHeader = false,
  });

  final String name;
  final String charges;
  final String makerCharges;
  final String fields;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isHeader ? 11 : 10,
      fontWeight: isHeader ? FontWeight.w900 : FontWeight.w700,
      color: isHeader ? _brandDark : _ink,
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFEFF8FF) : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEBD8C4)),
        ),
      ),
      child: Row(
        children: [
          _TemplateCell(
              text: isHeader ? tr(context, name) : name, flex: 3, style: style),
          _TemplateCell(
              text: isHeader ? tr(context, charges) : charges,
              flex: 2,
              style: style),
          _TemplateCell(
              text: isHeader ? tr(context, makerCharges) : makerCharges,
              flex: 2,
              style: style),
          _TemplateCell(
              text: isHeader ? tr(context, fields) : fields,
              flex: 3,
              style: style),
        ],
      ),
    );
  }
}

class _TemplateCell extends StatelessWidget {
  const _TemplateCell({
    required this.text,
    required this.flex,
    required this.style,
  });

  final String text;
  final int flex;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          style: style,
        ),
      ),
    );
  }
}

class _WorkersTableCard extends StatelessWidget {
  const _WorkersTableCard({
    required this.workers,
    required this.onAdd,
    required this.onWorkerTap,
  });

  final List<ShopWorker> workers;
  final VoidCallback onAdd;
  final ValueChanged<ShopWorker> onWorkerTap;

  @override
  Widget build(BuildContext context) {
    const rowHeight = 34.0;
    final table = Column(
      children: [
        const _WorkerTableHeader(),
        if (workers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(tr(context, 'No workers created')),
          )
        else
          for (final worker in workers)
            _WorkerTableRow(worker: worker, onTap: () => onWorkerTap(worker)),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'Workers'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Material(
                  color: const Color(0xFF20A35A),
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: const Color(0xFF20A35A).withValues(alpha: 0.32),
                  child: IconButton(
                    tooltip: tr(context, 'Create Worker'),
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEBD8C4)),
              ),
              child: workers.length > 10
                  ? SizedBox(
                      height: rowHeight * 11,
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(child: table),
                      ),
                    )
                  : table,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerTableHeader extends StatelessWidget {
  const _WorkerTableHeader();

  @override
  Widget build(BuildContext context) {
    return const _WorkerTableCells(
      name: 'Worker',
      speciality: 'Speciality',
      mobile: 'Mobile',
      password: 'Default password',
      wallet: 'Wallet',
      isHeader: true,
    );
  }
}

class _WorkerTableRow extends StatelessWidget {
  const _WorkerTableRow({required this.worker, required this.onTap});

  final ShopWorker worker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: _WorkerTableCells(
        name: worker.name,
        speciality: worker.speciality,
        mobile: worker.mobile,
        password: worker.defaultPassword,
        wallet: 'Rs ${worker.walletBalance}',
      ),
    );
  }
}

class _WorkerTableCells extends StatelessWidget {
  const _WorkerTableCells({
    required this.name,
    required this.speciality,
    required this.mobile,
    required this.password,
    required this.wallet,
    this.isHeader = false,
  });

  final String name;
  final String speciality;
  final String mobile;
  final String password;
  final String wallet;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final walletValue =
        int.tryParse(wallet.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
    final style = TextStyle(
      fontSize: isHeader ? 11 : 10,
      fontWeight: isHeader ? FontWeight.w900 : FontWeight.w700,
      color: isHeader ? _brandDark : _ink,
    );
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFEFF8FF) : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEBD8C4)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                isHeader ? tr(context, name) : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                isHeader ? tr(context, password) : password,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                tr(context, speciality),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                isHeader ? tr(context, mobile) : mobile,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                isHeader ? tr(context, wallet) : wallet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: isHeader
                    ? style
                    : style.copyWith(
                        color: walletValue < 0
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF176B32),
                        fontWeight: FontWeight.w900,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _defaultWorkerPassword(String name, String mobile) {
  final compactName = name.replaceAll(RegExp(r'\s+'), '');
  final digits = mobile.replaceAll(RegExp(r'\D'), '');
  final suffix =
      digits.length <= 6 ? digits : digits.substring(digits.length - 6);
  return '$compactName$suffix';
}

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({
    super.key,
    required this.profile,
    required this.customers,
    required this.orders,
    required this.templates,
    required this.onCustomerSaved,
    this.existing,
  });

  final ShopProfile profile;
  final List<TailorCustomer> customers;
  final List<TailorOrder> orders;
  final List<GarmentTemplate> templates;
  final ValueChanged<TailorCustomer> onCustomerSaved;
  final TailorOrder? existing;

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _customerSearch = TextEditingController();
  final _notes = TextEditingController();
  final _advancePayment = TextEditingController();
  final _weightKg = TextEditingController();
  String? _selectedCustomerPhone;
  late List<TailorCustomer> _customers;
  late List<OrderTemplateItem> _items;
  late DateTime _dueDate;
  String _payment = 'UPI';
  String _status = 'Measurements';
  bool _priority = false;

  @override
  void initState() {
    super.initState();
    _customers = [...widget.customers];
    final order = widget.existing;
    if (order != null) {
      _selectedCustomerPhone = _phoneForCustomerName(order.customerName);
      final selected = _selectedCustomer;
      if (selected != null) {
        _customerSearch.text = '${selected.name} - ${selected.phone}';
      }
      _items = [
        for (final item in order.items)
          OrderTemplateItem(
            templateName: item.templateName,
            quantity: item.quantity,
            status: item.status,
            charges: item.charges,
            makerCharges: item.makerCharges,
            measurementUpdatedAt: item.measurementUpdatedAt,
            measurements: Map.of(item.measurements),
            assignedWorkerByUnit: Map.of(item.assignedWorkerByUnit),
            workerPaymentStatusByUnit: Map.of(item.workerPaymentStatusByUnit),
          ),
      ];
      _notes.text = order.notes;
      _advancePayment.text = order.advancePayment.toString();
      _weightKg.text = order.weightKg.toString();
      _dueDate = order.dueDate;
      _payment = order.paymentMode;
      _status = order.status;
      _priority = order.priority;
    } else {
      _selectedCustomerPhone = null;
      _items = [];
      _dueDate = DateTime.now().add(const Duration(days: 7));
      _advancePayment.text = '0';
      _weightKg.text = '0';
    }
  }

  @override
  void dispose() {
    _customerSearch.dispose();
    _notes.dispose();
    _advancePayment.dispose();
    _weightKg.dispose();
    super.dispose();
  }

  TailorCustomer? get _selectedCustomer {
    for (final customer in _customers) {
      if (customer.phone == _selectedCustomerPhone) return customer;
    }
    return null;
  }

  String? _phoneForCustomerName(String name) {
    for (final customer in _customers) {
      if (customer.name == name) return customer.phone;
    }
    return null;
  }

  List<TailorCustomer> get _matchedCustomers {
    final query = _customerSearch.text.trim().toLowerCase();
    if (query.isEmpty) return _customers.take(5).toList();
    return _customers
        .where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              customer.phone.contains(query);
        })
        .take(6)
        .toList();
  }

  bool _hasPendingPayment(TailorCustomer customer) {
    final customerOrders =
        widget.orders.where((order) => order.customerName == customer.name);
    final totalBill =
        customerOrders.fold<int>(0, (sum, order) => sum + order.amount);
    final totalPaid = customerOrders.fold<int>(
      0,
      (sum, order) => sum + order.advancePayment,
    );
    return totalBill != totalPaid;
  }

  int get _total => _items.fold(0, (sum, item) => sum + item.total);

  int get _paidAmount => int.tryParse(_advancePayment.text.trim()) ?? 0;

  int get _balanceAmount => (_total - _paidAmount).clamp(0, _total).toInt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr(
              context, widget.existing == null ? 'NEW ORDER' : 'Edit Order'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader(title: 'Select Customer', action: 'Add Cust.'),
            const SizedBox(height: 10),
            TextField(
              controller: _customerSearch,
              inputFormatters: localizedTextInputFormatters(context),
              decoration: InputDecoration(
                labelText: tr(context, 'Search customer by name or mobile'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _selectedCustomerPhone == null
                    ? null
                    : IconButton(
                        tooltip: tr(context, 'Clear customer'),
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedCustomerPhone = null;
                            _customerSearch.clear();
                            _items = [];
                          });
                        },
                      ),
              ),
              onChanged: (_) => setState(() => _selectedCustomerPhone = null),
            ),
            const SizedBox(height: 10),
            if (_selectedCustomer != null)
              _SelectedCustomerCard(
                customer: _selectedCustomer!,
                hasPendingPayment: _hasPendingPayment(_selectedCustomer!),
              )
            else ...[
              for (final customer in _matchedCustomers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CustomerSearchCard(
                    customer: customer,
                    onTap: () => _selectCustomer(customer),
                  ),
                ),
              if (_customerSearch.text.trim().isNotEmpty &&
                  _matchedCustomers.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'No customer found'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _createCustomerFromOrder,
                            icon: const Icon(Icons.person_add_alt_outlined),
                            label: Text(tr(context, 'Create Customer')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_customerSearch.text.trim().isEmpty && _customers.isEmpty)
                const _EmptyState(
                  icon: Icons.people_outline,
                  title: 'No customers yet',
                  subtitle:
                      'Create a customer first, then continue this order.',
                ),
              if (_customerSearch.text.trim().isEmpty && _customers.isEmpty)
                const SizedBox(height: 8),
              if (_customerSearch.text.trim().isEmpty && _customers.isEmpty)
                FilledButton.icon(
                  onPressed: _createCustomerFromOrder,
                  icon: const Icon(Icons.person_add_alt_outlined),
                  label: Text(tr(context, 'Create Customer')),
                ),
            ],
            const SizedBox(height: 16),
            const _SectionHeader(title: 'Order Details', action: 'Due Date'),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _pickDueDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: tr(context, 'Order Due Date'),
                  prefixIcon: const Icon(Icons.event_outlined),
                ),
                child: Text(_formatDate(_dueDate)),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _priority,
              onChanged: (value) => setState(() => _priority = value),
              title: Text(tr(context, 'High Priority')),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: _SectionHeader(
                      title: 'Add Order Items', action: 'Templates'),
                ),
                Material(
                  color: const Color(0xFFEFF8FF),
                  shape: const CircleBorder(),
                  elevation: 1,
                  child: IconButton(
                    tooltip: tr(context, 'Add Template'),
                    onPressed:
                        _selectedCustomer == null || widget.templates.isEmpty
                            ? null
                            : () => _openOrderItemDialog(),
                    icon: const Icon(Icons.add_box_outlined, color: _brandDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_items.isEmpty)
              const _EmptyState(
                icon: Icons.checkroom_outlined,
                title: 'No templates selected',
                subtitle:
                    'Add one or more templates with quantity and measurements.',
              )
            else
              for (var index = 0; index < _items.length; index++)
                Card(
                  child: ListTile(
                    onTap: () => _openOrderItemDialog(index: index),
                    leading: const Icon(Icons.checkroom_outlined),
                    title: Text(_items[index].templateName),
                    subtitle: Text(
                      '${tr(context, 'Qty')} ${_items[index].quantity} x Rs ${_items[index].rate}\n'
                      '${_items[index].measurements.length} ${tr(context, 'measurements assigned')}',
                    ),
                    isThreeLine: true,
                    trailing: Text('Rs ${_items[index].total}'),
                  ),
                ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              inputFormatters: localizedTextInputFormatters(context),
              minLines: 2,
              maxLines: 4,
              decoration:
                  InputDecoration(labelText: tr(context, 'Additional Notes')),
            ),
            const SizedBox(height: 16),
            const _SectionHeader(
                title: 'Review & Payment', action: 'Order Summary'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in _items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.templateName} (${item.quantity} x Rs ${item.rate})',
                              ),
                            ),
                            Text('Rs ${item.total}'),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(context, 'Total'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          'Rs $_total',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _advancePayment,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: tr(context, 'Advance Payment')),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightKg,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                          labelText: tr(context, 'Weight in kg')),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(context, 'Paid Amount'),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Text('Rs $_paidAmount'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(context, 'Balance Amount'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          'Rs $_balanceAmount',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _payment,
              decoration:
                  InputDecoration(labelText: tr(context, 'PAYMENT MODE')),
              items: const [
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Card', child: Text('Card')),
              ],
              onChanged: (value) => setState(() => _payment = value ?? 'UPI'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(labelText: tr(context, 'Status')),
              items: [
                DropdownMenuItem(
                    value: 'Measurements',
                    child: Text(tr(context, 'Measurements'))),
                DropdownMenuItem(
                    value: 'In Stitching',
                    child: Text(tr(context, 'In Stitching'))),
                DropdownMenuItem(
                    value: 'Ready', child: Text(tr(context, 'Ready'))),
                DropdownMenuItem(
                    value: 'Delivered', child: Text(tr(context, 'Delivered'))),
              ],
              onChanged: (value) =>
                  setState(() => _status = value ?? 'Measurements'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                tr(context,
                    widget.existing == null ? 'Order Created' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCustomer(TailorCustomer customer) {
    setState(() {
      _selectedCustomerPhone = customer.phone;
      _customerSearch.text = '${customer.name} - ${customer.phone}';
      _items = [];
    });
  }

  Future<void> _createCustomerFromOrder() async {
    final result = await showDialog<TailorCustomer>(
      context: context,
      builder: (_) => const CustomerDialog(),
    );
    if (result == null) return;
    widget.onCustomerSaved(result);
    setState(() {
      final index =
          _customers.indexWhere((customer) => customer.phone == result.phone);
      if (index >= 0) {
        _customers[index] = result;
      } else {
        _customers.insert(0, result);
      }
      _selectedCustomerPhone = result.phone;
      _customerSearch.text = '${result.name} - ${result.phone}';
      _items = [];
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _openOrderItemDialog({int? index}) async {
    final customer = _selectedCustomer;
    if (customer == null) return;
    final result = await showDialog<OrderTemplateItem>(
      context: context,
      builder: (_) => OrderTemplateDialog(
        customer: customer,
        templates: widget.templates,
        existing: index == null ? null : _items[index],
      ),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  Future<void> _save() async {
    final customer = _selectedCustomer;
    if (customer == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'Select a customer and add a template.')),
        ),
      );
      return;
    }
    final order = TailorOrder(
      id: widget.existing?.id ??
          'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      customerName: customer.name,
      items: _items,
      orderDate: widget.existing?.orderDate ?? DateTime.now(),
      dueDate: _dueDate,
      status: _status,
      paymentMode: _payment,
      advancePayment: _paidAmount.clamp(0, _total).toInt(),
      payments: widget.existing != null
          ? widget.existing!.payments
          : _paidAmount > 0
              ? [
                  OrderPayment(
                    amount: _paidAmount.clamp(0, _total).toInt(),
                    mode: _payment,
                    paidAt: DateTime.now(),
                  ),
                ]
              : [],
      weightKg: double.tryParse(_weightKg.text.trim()) ?? 0,
      tailor: 'Master Tailor',
      priority: _priority,
      notes: localizedInputText(context, _notes.text).trim(),
    );
    if (widget.existing == null) {
      await showDialog<void>(
        context: context,
        builder: (_) => OrderReceiptDialog(
          profile: widget.profile,
          customer: customer,
          order: order,
        ),
      );
      if (!mounted) return;
    }
    Navigator.of(context).pop(order);
  }
}

enum ReceiptCopyType { customer, shop }

class OrderReceiptDialog extends StatefulWidget {
  const OrderReceiptDialog({
    super.key,
    required this.profile,
    required this.customer,
    required this.order,
  });

  final ShopProfile profile;
  final TailorCustomer customer;
  final TailorOrder order;

  @override
  State<OrderReceiptDialog> createState() => _OrderReceiptDialogState();
}

class _OrderReceiptDialogState extends State<OrderReceiptDialog> {
  ReceiptCopyType _copyType = ReceiptCopyType.customer;
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(context, 'Receipt Preview'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: tr(context, 'Close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => setState(
                              () => _copyType = ReceiptCopyType.customer,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  _copyType == ReceiptCopyType.customer
                                      ? const Color(0xFFFFEAD2)
                                      : null,
                            ),
                            child:
                                Text(_receiptLabel(context, 'Customer copy')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => setState(
                              () => _copyType = ReceiptCopyType.shop,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _copyType == ReceiptCopyType.shop
                                  ? const Color(0xFFFFEAD2)
                                  : null,
                            ),
                            child: Text(_receiptLabel(context, 'Shop use')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: OrderReceiptPreview(
                        profile: widget.profile,
                        customer: widget.customer,
                        order: widget.order,
                        copyType: _copyType,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isPrinting ? null : _printReceipt,
                  icon: Icon(
                    _isPrinting ? Icons.hourglass_top : Icons.print_outlined,
                  ),
                  label: Text(
                    _isPrinting
                        ? _receiptLabel(context, 'Printing...')
                        : tr(context, 'Done'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);
    try {
      final language = AppLanguageScope.of(context).language;
      final bytes = await _buildReceiptPdf(
        profile: widget.profile,
        customer: widget.customer,
        order: widget.order,
        copyType: _copyType,
        language: language,
      );
      await Printing.layoutPdf(
        name: '${widget.order.id}-${_copyType.name}-receipt.pdf',
        format: const PdfPageFormat(
          88 * PdfPageFormat.mm,
          240 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        ),
        onLayout: (_) async => bytes,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${_receiptLabel(context, 'Print failed')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }
}

class OrderReceiptPreview extends StatelessWidget {
  const OrderReceiptPreview({
    super.key,
    required this.profile,
    required this.customer,
    required this.order,
    required this.copyType,
  });

  final ShopProfile profile;
  final TailorCustomer customer;
  final TailorOrder order;
  final ReceiptCopyType copyType;

  @override
  Widget build(BuildContext context) {
    final isCustomerCopy = copyType == ReceiptCopyType.customer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE0D1C0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: 352,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '(${_receiptLabel(
                    context,
                    isCustomerCopy ? 'Customer copy' : 'Shop use',
                  )})',
                  style: _receiptTextStyle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                profile.shopName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _receiptLabel(
                  context,
                  'Specialist in Suit, Shirt & Pant Stitching',
                ),
                textAlign: TextAlign.center,
                style: _receiptTextStyle,
              ),
              Text(
                profile.address,
                textAlign: TextAlign.center,
                style: _receiptTextStyle,
              ),
              Text(
                '${_receiptLabel(context, 'Mobile')}: ${profile.phone}',
                textAlign: TextAlign.center,
                style: _receiptTextStyle,
              ),
              const _ReceiptDashedDivider(),
              _ReceiptInfoRow(
                leftLabel: _receiptLabel(context, 'Bill No:'),
                leftValue: '',
                rightLabel: '',
                rightValue: _receiptBillNumber(order.id),
                rightBold: true,
              ),
              _ReceiptInfoRow(
                leftLabel: _receiptLabel(context, 'Date:'),
                leftValue: '',
                rightLabel: '',
                rightValue: _formatReceiptDateTime(order.orderDate),
              ),
              _ReceiptInfoRow(
                leftLabel: _receiptLabel(context, 'Customer:'),
                leftValue: '',
                rightLabel: '',
                rightValue: customer.name,
              ),
              _ReceiptInfoRow(
                leftLabel: _receiptLabel(context, 'Mobile:'),
                leftValue: '',
                rightLabel: '',
                rightValue: customer.phone,
              ),
              _ReceiptInfoRow(
                leftLabel: _receiptLabel(context, 'Delivery:'),
                leftValue: '',
                rightLabel: '',
                rightValue: _formatReceiptDate(order.dueDate),
              ),
              const _ReceiptDashedDivider(),
              _ReceiptItemHeader(copyType: copyType),
              const _ReceiptDashedDivider(top: 3, bottom: 4),
              for (var index = 0; index < order.items.length; index++)
                _ReceiptItemRow(item: order.items[index], copyType: copyType),
              if (isCustomerCopy) ...[
                const _ReceiptDashedDivider(),
                _ReceiptAmountRow(
                  label: _receiptLabel(context, 'Subtotal'),
                  value: order.amount,
                ),
                _ReceiptAmountRow(
                  label: _receiptLabel(context, 'Total'),
                  value: order.amount,
                  large: true,
                ),
                _ReceiptAmountRow(
                  label: _receiptLabel(context, 'Paid'),
                  value: order.advancePayment,
                ),
                _ReceiptAmountRow(
                  label: _receiptLabel(context, 'Balance'),
                  value: order.balanceAmount,
                  bold: true,
                ),
                const _ReceiptDashedDivider(),
                _ReceiptInfoRow(
                  leftLabel: _receiptLabel(context, 'Payment Mode:'),
                  leftValue: '',
                  rightLabel: '',
                  rightValue: order.paymentMode,
                ),
                _ReceiptInfoRow(
                  leftLabel: _receiptLabel(context, 'Order Status:'),
                  leftValue: '',
                  rightLabel: '',
                  rightValue: _receiptLabel(context, order.status),
                ),
              ],
              const _ReceiptDashedDivider(),
              Text(
                _receiptLabel(context, 'Thank you for visiting!'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _receiptLabel(
                  context,
                  'Please carry this receipt during delivery.\nGoods once stitched cannot be returned.',
                ),
                textAlign: TextAlign.center,
                style: _receiptTextStyle,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: Center(
                  child: ContactBarcode(data: customer.phone),
                ),
              ),
              Text(
                customer.phone,
                textAlign: TextAlign.center,
                style: _receiptTextStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _receiptTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 12,
  height: 1.22,
  letterSpacing: 0,
);

class _ReceiptDashedDivider extends StatelessWidget {
  const _ReceiptDashedDivider({this.top = 7, this.bottom = 7});

  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: CustomPaint(
        painter: _DashedLinePainter(),
        child: const SizedBox(height: 1),
      ),
    );
  }
}

class _ReceiptInfoRow extends StatelessWidget {
  const _ReceiptInfoRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.rightBold = false,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final bool rightBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(leftLabel, style: _receiptTextStyle),
          ),
          if (leftValue.isNotEmpty)
            Expanded(
              child: Text(
                leftValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _receiptTextStyle,
              ),
            )
          else
            const Spacer(),
          if (rightLabel.isNotEmpty) Text(rightLabel, style: _receiptTextStyle),
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                rightValue,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: _receiptTextStyle.copyWith(
                  fontWeight: rightBold ? FontWeight.w900 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItemHeader extends StatelessWidget {
  const _ReceiptItemHeader({required this.copyType});

  final ReceiptCopyType copyType;

  @override
  Widget build(BuildContext context) {
    final isCustomerCopy = copyType == ReceiptCopyType.customer;
    return Row(
      children: [
        Expanded(
          flex: isCustomerCopy ? 5 : 4,
          child: Text(
            _receiptLabel(context, 'Item'),
            style: _receiptHeaderStyle,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            _receiptLabel(context, 'Qty'),
            textAlign: TextAlign.right,
            style: _receiptHeaderStyle,
          ),
        ),
        if (isCustomerCopy) ...[
          Expanded(
            flex: 3,
            child: Text(
              _receiptLabel(context, 'Rate'),
              textAlign: TextAlign.right,
              style: _receiptHeaderStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _receiptLabel(context, 'Amt'),
              textAlign: TextAlign.right,
              style: _receiptHeaderStyle,
            ),
          ),
        ] else
          Expanded(
            flex: 7,
            child: Text(
              _receiptLabel(context, 'Measurements'),
              textAlign: TextAlign.right,
              style: _receiptHeaderStyle,
            ),
          ),
      ],
    );
  }
}

const _receiptHeaderStyle = TextStyle(
  color: Colors.black,
  fontSize: 12,
  fontWeight: FontWeight.w900,
  height: 1.2,
);

class _ReceiptItemRow extends StatelessWidget {
  const _ReceiptItemRow({required this.item, required this.copyType});

  final OrderTemplateItem item;
  final ReceiptCopyType copyType;

  @override
  Widget build(BuildContext context) {
    final isCustomerCopy = copyType == ReceiptCopyType.customer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isCustomerCopy ? 5 : 4,
            child: Text(item.templateName, style: _receiptTextStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.quantity.toString(),
              textAlign: TextAlign.right,
              style: _receiptTextStyle,
            ),
          ),
          if (isCustomerCopy) ...[
            Expanded(
              flex: 3,
              child: Text(
                item.rate.toString(),
                textAlign: TextAlign.right,
                style: _receiptTextStyle,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                item.total.toString(),
                textAlign: TextAlign.right,
                style: _receiptTextStyle,
              ),
            ),
          ] else
            Expanded(
              flex: 7,
              child: Text(
                _measurementSummary(item),
                textAlign: TextAlign.right,
                style: _receiptTextStyle,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReceiptAmountRow extends StatelessWidget {
  const _ReceiptAmountRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.large = false,
  });

  final String label;
  final int value;
  final bool bold;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: Colors.black,
      fontSize: large ? 16 : 12,
      fontWeight: bold || large ? FontWeight.w900 : FontWeight.w400,
      height: 1.25,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(_formatCurrency(value), style: style),
        ],
      ),
    );
  }
}

class ContactBarcode extends StatelessWidget {
  const ContactBarcode({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Code39BarcodePainter(data),
      size: const Size(150, 40),
    );
  }
}

class _Code39BarcodePainter extends CustomPainter {
  const _Code39BarcodePainter(this.data);

  final String data;

  static const Map<String, String> _patterns = {
    '0': 'nnnwwnwnw',
    '1': 'wnnwnnnnw',
    '2': 'nnwwnnnnw',
    '3': 'wnwwnnnnn',
    '4': 'nnnwwnnnw',
    '5': 'wnnwwnnnn',
    '6': 'nnwwwnnnn',
    '7': 'nnnwnnwnw',
    '8': 'wnnwnnwnn',
    '9': 'nnwwnnwnn',
    '*': 'nwnnwnwnn',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final digits = data.replaceAll(RegExp(r'\D'), '');
    final encoded = '*$digits*';
    final units = encoded.split('').fold<int>(
      0,
      (total, char) {
        final pattern = _patterns[char] ?? _patterns['0']!;
        final patternUnits = pattern.split('').fold<int>(
              0,
              (sum, mark) => sum + (mark == 'w' ? 3 : 1),
            );
        return total + patternUnits + 1;
      },
    );
    final unit = size.width / units;
    final paint = Paint()..color = Colors.black;
    var x = 0.0;
    for (final char in encoded.split('')) {
      final pattern = _patterns[char] ?? _patterns['0']!;
      for (var i = 0; i < pattern.length; i++) {
        final width = unit * (pattern[i] == 'w' ? 3 : 1);
        if (i.isEven) {
          canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
        }
        x += width;
      }
      x += unit;
    }
  }

  @override
  bool shouldRepaint(covariant _Code39BarcodePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;
    const dashWidth = 2.5;
    const dashGap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _receiptLabel(BuildContext context, String value) {
  return _receiptLabelForLanguage(AppLanguageScope.of(context).language, value);
}

String _receiptLabelForLanguage(AppLanguage language, String value) {
  if (language == AppLanguage.en) return value;
  return _mrReceiptLabels[value] ?? value;
}

const Map<String, String> _mrReceiptLabels = {
  'Receipt Preview': 'पावती पूर्वावलोकन',
  'Customer copy': 'ग्राहक प्रत',
  'Shop use': 'दुकान वापर',
  'Printing...': 'प्रिंट होत आहे...',
  'Print failed': 'प्रिंट अयशस्वी',
  'Specialist in Suit, Shirt & Pant Stitching':
      'सूट, शर्ट आणि पॅन्ट शिवणकाम तज्ञ',
  'Mobile': 'मोबाइल',
  'Bill No:': 'बिल क्र.:',
  'Date:': 'दिनांक:',
  'Customer:': 'ग्राहक:',
  'Mobile:': 'मोबाइल:',
  'Delivery:': 'डिलिव्हरी:',
  'Item': 'आयटम',
  'Qty': 'नग',
  'Rate': 'दर',
  'Amt': 'रक्कम',
  'Measurements': 'मापे',
  'Subtotal': 'उपएकूण',
  'Total': 'एकूण',
  'Paid': 'भरले',
  'Balance': 'बाकी',
  'Payment Mode:': 'पेमेंट मोड:',
  'Order Status:': 'ऑर्डर स्थिती:',
  'Measurements not added': 'मापे जोडलेली नाहीत',
  'Thank you for visiting!': 'भेट दिल्याबद्दल धन्यवाद!',
  'Please carry this receipt during delivery.\nGoods once stitched cannot be returned.':
      'डिलिव्हरीवेळी ही पावती सोबत आणा.\nशिवलेला माल परत घेतला जाणार नाही.',
  'In Stitching': 'शिवणकामात',
  'Ready': 'तयार',
  'Delivered': 'डिलिव्हर',
};

String _measurementSummary(OrderTemplateItem item) {
  if (item.measurements.isEmpty) return 'Measurements not added';
  return item.measurements.entries
      .map((entry) => '${entry.key} ${entry.value}')
      .join(', ');
}

Future<Uint8List> _buildReceiptPdf({
  required ShopProfile profile,
  required TailorCustomer customer,
  required TailorOrder order,
  required ReceiptCopyType copyType,
  required AppLanguage language,
}) async {
  final document = pw.Document();
  final isCustomerCopy = copyType == ReceiptCopyType.customer;
  pw.Font regularFont = pw.Font.helvetica();
  pw.Font boldFont = pw.Font.helveticaBold();
  if (language == AppLanguage.mr) {
    try {
      regularFont = await PdfGoogleFonts.notoSansDevanagariRegular();
      boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    } catch (_) {
      regularFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
  }
  final regular = pw.TextStyle(font: regularFont, fontSize: 8.8, height: 1.15);
  final bold = pw.TextStyle(
    font: boldFont,
    fontSize: 8.8,
    fontWeight: pw.FontWeight.bold,
    height: 1.15,
  );

  pw.Widget line() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text('-' * 48, style: regular),
      );
  pw.Widget info(String label, String value, {bool strong = false}) => pw.Row(
        children: [
          pw.SizedBox(width: 54, child: pw.Text(label, style: regular)),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: strong ? bold : regular,
              maxLines: 1,
            ),
          ),
        ],
      );
  pw.Widget amount(String label, int value, {bool strong = false}) => pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: strong ? bold : regular)),
          pw.Text(_formatCurrency(value), style: strong ? bold : regular),
        ],
      );

  document.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(
        88 * PdfPageFormat.mm,
        240 * PdfPageFormat.mm,
        marginAll: 3 * PdfPageFormat.mm,
      ),
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            '(${_receiptLabelForLanguage(language, isCustomerCopy ? 'Customer copy' : 'Shop use')})',
            textAlign: pw.TextAlign.right,
            style: regular,
          ),
          pw.Text(
            profile.shopName.toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: bold.copyWith(fontSize: 14),
          ),
          pw.Text(
            _receiptLabelForLanguage(
              language,
              'Specialist in Suit, Shirt & Pant Stitching',
            ),
            textAlign: pw.TextAlign.center,
            style: regular,
          ),
          pw.Text(profile.address,
              textAlign: pw.TextAlign.center, style: regular),
          pw.Text(
            '${_receiptLabelForLanguage(language, 'Mobile')}: ${profile.phone}',
            textAlign: pw.TextAlign.center,
            style: regular,
          ),
          line(),
          info(_receiptLabelForLanguage(language, 'Bill No:'),
              _receiptBillNumber(order.id),
              strong: true),
          info(_receiptLabelForLanguage(language, 'Date:'),
              _formatReceiptDateTime(order.orderDate)),
          info(_receiptLabelForLanguage(language, 'Customer:'), customer.name),
          info(_receiptLabelForLanguage(language, 'Mobile:'), customer.phone),
          info(_receiptLabelForLanguage(language, 'Delivery:'),
              _formatReceiptDate(order.dueDate)),
          line(),
          for (final item in order.items)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                isCustomerCopy
                    ? '${item.templateName}  x${item.quantity}   ${item.rate}   ${item.total}'
                    : '${item.templateName}  x${item.quantity}   ${_measurementSummary(item)}',
                style: regular,
              ),
            ),
          if (isCustomerCopy) ...[
            line(),
            amount(
                _receiptLabelForLanguage(language, 'Subtotal'), order.amount),
            amount(_receiptLabelForLanguage(language, 'Total'), order.amount,
                strong: true),
            amount(_receiptLabelForLanguage(language, 'Paid'),
                order.advancePayment),
            amount(_receiptLabelForLanguage(language, 'Balance'),
                order.balanceAmount,
                strong: true),
            line(),
            info(_receiptLabelForLanguage(language, 'Payment Mode:'),
                order.paymentMode),
            info(_receiptLabelForLanguage(language, 'Order Status:'),
                _receiptLabelForLanguage(language, order.status)),
          ],
          line(),
          pw.Text(
            _receiptLabelForLanguage(language, 'Thank you for visiting!'),
            textAlign: pw.TextAlign.center,
            style: bold,
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: Barcode.code39(),
              data: customer.phone.replaceAll(RegExp(r'\D'), ''),
              width: 112,
              height: 28,
              drawText: false,
            ),
          ),
          pw.Text(customer.phone,
              textAlign: pw.TextAlign.center, style: regular),
        ],
      ),
    ),
  );
  return document.save();
}

String _receiptBillNumber(String orderId) {
  final digits = orderId.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return orderId;
  return 'RT-2026-${digits.padLeft(5, '0')}';
}

String _formatCurrency(int amount) {
  final text = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return '₹ ${buffer.toString()}.00';
}

class _SelectedCustomerCard extends StatelessWidget {
  const _SelectedCustomerCard({
    required this.customer,
    required this.hasPendingPayment,
  });

  final TailorCustomer customer;
  final bool hasPendingPayment;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF8FF),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: _brand,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(customer.phone),
                  Text(
                    customer.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: hasPendingPayment
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF176B32),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerSearchCard extends StatelessWidget {
  const _CustomerSearchCard({required this.customer, required this.onTap});

  final TailorCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: const Icon(Icons.person_outline),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${customer.phone}\n${customer.address}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class OrderTemplateDialog extends StatefulWidget {
  const OrderTemplateDialog({
    super.key,
    required this.customer,
    required this.templates,
    this.existing,
  });

  final TailorCustomer customer;
  final List<GarmentTemplate> templates;
  final OrderTemplateItem? existing;

  @override
  State<OrderTemplateDialog> createState() => _OrderTemplateDialogState();
}

class _OrderTemplateDialogState extends State<OrderTemplateDialog> {
  late GarmentTemplate _template;
  late int _quantity;
  late String _templateStatus;
  late Map<String, String> _measurements;
  late DateTime _measurementUpdatedAt;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _template = existing == null
        ? widget.templates.first
        : widget.templates.firstWhere(
            (template) => template.name == existing.templateName,
            orElse: () => widget.templates.first,
          );
    _quantity = existing?.quantity ?? 1;
    _templateStatus = existing?.status ?? 'Measurements';
    _measurements = existing == null
        ? _measurementFor(_template)
        : Map.of(existing.measurements);
    _measurementUpdatedAt = existing?.measurementUpdatedAt ??
        widget.customer.measurementsByTemplate[_template.name]?.updatedAt ??
        DateTime.now();
  }

  Map<String, String> _measurementFor(GarmentTemplate template) {
    return Map.of(
      widget.customer.measurementsByTemplate[template.name]?.values ?? {},
    );
  }

  int get _lineTotal => _template.rate * _quantity;

  @override
  Widget build(BuildContext context) {
    final hasMeasurements = _measurements.isNotEmpty;
    return AlertDialog(
      title: Text(tr(
          context, widget.existing == null ? 'Add Template' : 'Edit Template')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _template.name,
              decoration: InputDecoration(labelText: tr(context, 'Template')),
              items: [
                for (final template in widget.templates)
                  DropdownMenuItem(
                    value: template.name,
                    child: Text('${template.name} - Rs ${template.rate}'),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _template = widget.templates.firstWhere(
                    (template) => template.name == value,
                  );
                  _measurements = _measurementFor(_template);
                  _measurementUpdatedAt = widget.customer
                          .measurementsByTemplate[_template.name]?.updatedAt ??
                      DateTime.now();
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.outlined(
                  onPressed:
                      _quantity <= 1 ? null : () => setState(() => _quantity--),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${tr(context, 'Quantity')}: $_quantity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _templateStatus,
              decoration:
                  InputDecoration(labelText: tr(context, 'Template Status')),
              items: [
                DropdownMenuItem(
                    value: 'Measurements',
                    child: Text(tr(context, 'Measurements'))),
                DropdownMenuItem(
                    value: 'In Stitching',
                    child: Text(tr(context, 'In Stitching'))),
                DropdownMenuItem(
                    value: 'Ready', child: Text(tr(context, 'Ready'))),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _templateStatus = value);
              },
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${tr(context, 'Charges')}: Rs ${_template.charges}'),
                    Text(
                        '${tr(context, 'Maker charges')}: Rs ${_template.makerCharges}'),
                    const Divider(),
                    Text('${tr(context, 'Line total')}: Rs $_lineTotal'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasMeasurements
                  ? '${tr(context, 'Measurements assigned for')} ${_template.name}'
                  : tr(context,
                      'No measurements yet for this customer and template.'),
            ),
            if (hasMeasurements) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _measurements.entries)
                    Chip(label: Text('${entry.key}: ${entry.value}')),
                ],
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _takeMeasurement,
              icon: const Icon(Icons.straighten),
              label: Text(tr(context, 'Take Measurement')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: _measurements.isEmpty ? null : _save,
          child: Text(tr(context, 'Add Template')),
        ),
      ],
    );
  }

  Future<void> _takeMeasurement() async {
    final result = await showDialog<TemplateMeasurement>(
      context: context,
      builder: (_) => MeasurementDialog(
        template: _template,
        existing: TemplateMeasurement(
          templateName: _template.name,
          updatedAt: _measurementUpdatedAt,
          values: _measurements,
        ),
      ),
    );
    if (result == null) return;
    widget.customer.measurementsByTemplate[_template.name] = result;
    setState(() {
      _measurements = Map.of(result.values);
      _measurementUpdatedAt = result.updatedAt;
    });
  }

  void _save() {
    Navigator.of(context).pop(
      OrderTemplateItem(
        templateName: _template.name,
        quantity: _quantity,
        status: _templateStatus,
        charges: _template.charges,
        makerCharges: _template.makerCharges,
        measurementUpdatedAt: _measurementUpdatedAt,
        measurements: Map.of(_measurements),
        assignedWorkerByUnit: {
          for (final entry in widget.existing?.assignedWorkerByUnit.entries ??
              const Iterable<MapEntry<int, String>>.empty())
            if (entry.key < _quantity) entry.key: entry.value,
        },
        workerPaymentStatusByUnit: {
          for (final entry
              in widget.existing?.workerPaymentStatusByUnit.entries ??
                  const Iterable<MapEntry<int, String>>.empty())
            if (entry.key < _quantity) entry.key: entry.value,
        },
      ),
    );
  }
}

class MeasurementDialog extends StatefulWidget {
  const MeasurementDialog({
    super.key,
    required this.template,
    required this.existing,
  });

  final GarmentTemplate template;
  final TemplateMeasurement existing;

  @override
  State<MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends State<MeasurementDialog> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.template.fields)
        field: TextEditingController(text: widget.existing.values[field] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text('${tr(context, 'Take Measurement -')} ${widget.template.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in _controllers.entries) ...[
              TextField(
                controller: entry.value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: entry.key),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(tr(context, 'Save Measurements')),
        ),
      ],
    );
  }

  void _save() {
    Navigator.of(context).pop(
      TemplateMeasurement(
        templateName: widget.template.name,
        updatedAt: DateTime.now(),
        values: {
          for (final entry in _controllers.entries)
            if (entry.value.text.trim().isNotEmpty)
              entry.key: entry.value.text.trim(),
        },
      ),
    );
  }
}

class CustomerDialog extends StatefulWidget {
  const CustomerDialog({super.key, this.customer});

  final TailorCustomer? customer;

  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    if (customer != null) {
      _name.text = customer.name;
      _phone.text = customer.phone;
      _address.text = customer.address;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        tr(context,
            widget.customer == null ? 'Create New Customer' : 'Edit Customer'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              inputFormatters: localizedTextInputFormatters(context),
              decoration:
                  InputDecoration(labelText: tr(context, 'Customer Name')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration:
                  InputDecoration(labelText: tr(context, 'Mobile Number')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _address,
              inputFormatters: localizedTextInputFormatters(context),
              maxLines: 2,
              decoration:
                  InputDecoration(labelText: tr(context, 'Short Address')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context, 'Cancel'))),
        FilledButton(
            onPressed: _save, child: Text(tr(context, 'Save Customer'))),
      ],
    );
  }

  void _save() {
    Navigator.of(context).pop(
      TailorCustomer(
        name: localizedInputText(context, _name.text).trim().isEmpty
            ? 'Customer'
            : localizedInputText(context, _name.text).trim(),
        phone: _phone.text.trim().isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : _phone.text.trim(),
        address: localizedInputText(context, _address.text).trim(),
        measurementsByTemplate:
            Map.of(widget.customer?.measurementsByTemplate ?? {}),
      ),
    );
  }
}

class TemplateDialog extends StatefulWidget {
  const TemplateDialog({super.key, this.template});

  final GarmentTemplate? template;

  @override
  State<TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<TemplateDialog> {
  final _name = TextEditingController();
  final _charges = TextEditingController();
  final _makerCharges = TextEditingController();
  final _field = TextEditingController();
  late List<String> _fields;

  @override
  void initState() {
    super.initState();
    _name.text = widget.template?.name ?? '';
    _charges.text = widget.template?.charges.toString() ?? '';
    _makerCharges.text = widget.template?.makerCharges.toString() ?? '';
    _fields = [...?widget.template?.fields];
  }

  @override
  void dispose() {
    _name.dispose();
    _charges.dispose();
    _makerCharges.dispose();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr(context,
          widget.template == null ? 'Create Template' : 'Edit Template')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              inputFormatters: localizedTextInputFormatters(context),
              decoration:
                  InputDecoration(labelText: tr(context, 'Template Name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _charges,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr(context, 'Charges')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _makerCharges,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: tr(context, 'Maker Charges')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _field,
                    inputFormatters: localizedTextInputFormatters(context),
                    decoration: InputDecoration(
                      labelText: tr(context, 'Add custom field'),
                      hintText: tr(context, 'e.g. APEX POINT'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addField,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final field in _fields)
                  InputChip(
                    label: Text(field),
                    onDeleted: () => setState(() => _fields.remove(field)),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context, 'Cancel'))),
        FilledButton(
            onPressed: _save, child: Text(tr(context, 'Save Template'))),
      ],
    );
  }

  void _addField() {
    final value = localizedInputText(context, _field.text).trim();
    if (value.isEmpty) return;
    setState(() {
      _fields.add(value);
      _field.clear();
    });
  }

  void _save() {
    Navigator.of(context).pop(
      GarmentTemplate(
        name: localizedInputText(context, _name.text).trim().isEmpty
            ? 'CUSTOM TEMPLATE'
            : localizedInputText(context, _name.text).trim(),
        charges: int.tryParse(_charges.text.trim()) ?? 0,
        makerCharges: int.tryParse(_makerCharges.text.trim()) ?? 0,
        fields: _fields.isEmpty
            ? ['Chest', 'Waist', 'Length']
            : [for (final field in _fields) localizedInputText(context, field)],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onTap});

  final TailorOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: order.priority
                ? const Color(0xFFFFE3D1)
                : const Color(0xFFE8F3EC),
            child: Icon(order.priority ? Icons.priority_high : Icons.checkroom,
                color: _brand),
          ),
          title: Text(order.summary),
          subtitle: Text(
              '${order.customerName} - ${tr(context, order.status)} - ${_formatDate(order.dueDate)} - ${order.id}'),
          trailing: Text('Rs ${order.amount}'),
        ),
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.orders,
    this.isReady = false,
    this.onTap,
  });

  final TailorCustomer customer;
  final List<TailorOrder> orders;
  final bool isReady;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final totalBill = orders.fold<int>(0, (sum, order) => sum + order.amount);
    final totalPaid =
        orders.fold<int>(0, (sum, order) => sum + order.advancePayment);
    final outstanding = (totalBill - totalPaid).clamp(0, totalBill).toInt();
    final inStitching =
        orders.where((order) => order.status == 'In Stitching').length;
    final isNil = outstanding == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isReady ? 10 : 0,
            sigmaY: isReady ? 10 : 0,
          ),
          child: Card(
            color: isReady ? const Color(0xCCE7F8EA) : null,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(child: Icon(Icons.person_outline)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(customer.phone),
                          Text(
                            customer.address.isEmpty
                                ? tr(context, 'No address')
                                : customer.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${tr(context, 'Bill')} Rs $totalBill | ${tr(context, 'Paid')} Rs $totalPaid',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isNil ? 'NIL' : 'Rs $outstanding',
                          style: TextStyle(
                            color: isNil ? Colors.green.shade800 : Colors.red,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${tr(context, 'Orders')} ${orders.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${tr(context, 'Stitch')} $inStitching',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          isReady
                              ? Icons.check_circle_outline
                              : Icons.chevron_right,
                          color: isReady ? Colors.green.shade700 : null,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricData> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(item.icon, color: _brand),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(item.label),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            tr(context, title),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(tr(context, action), style: const TextStyle(color: _brand)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 44, color: _brand),
            const SizedBox(height: 10),
            Text(tr(context, title),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(tr(context, subtitle), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class ShopProfile {
  const ShopProfile({
    required this.ownerName,
    required this.shopName,
    required this.phone,
    required this.address,
    required this.maxOrdersPerDay,
    required this.openDays,
  });

  final String ownerName;
  final String shopName;
  final String phone;
  final String address;
  final int maxOrdersPerDay;
  final String openDays;
}

class ShopWorker {
  const ShopWorker({
    required this.name,
    required this.mobile,
    required this.speciality,
    required this.roles,
    required this.username,
    required this.defaultPassword,
    required this.password,
    required this.mustResetPassword,
    required this.walletBalance,
    this.payments = const [],
  });

  final String name;
  final String mobile;
  final String speciality;
  final List<String> roles;
  final String username;
  final String defaultPassword;
  final String password;
  final bool mustResetPassword;
  final int walletBalance;
  final List<WorkerPayment> payments;

  ShopWorker copyWith({
    String? password,
    bool? mustResetPassword,
    int? walletBalance,
    List<WorkerPayment>? payments,
  }) {
    return ShopWorker(
      name: name,
      mobile: mobile,
      speciality: speciality,
      roles: [...roles],
      username: username,
      defaultPassword: defaultPassword,
      password: password ?? this.password,
      mustResetPassword: mustResetPassword ?? this.mustResetPassword,
      walletBalance: walletBalance ?? this.walletBalance,
      payments: payments ?? [...this.payments],
    );
  }
}

class WorkerPayment {
  const WorkerPayment({
    required this.amount,
    required this.paidAt,
    required this.note,
  });

  final int amount;
  final DateTime paidAt;
  final String note;
}

class TailorCustomer {
  TailorCustomer({
    required this.name,
    required this.phone,
    required this.address,
    Map<String, TemplateMeasurement>? measurementsByTemplate,
  }) : measurementsByTemplate = measurementsByTemplate ?? {};

  final String name;
  final String phone;
  final String address;
  final Map<String, TemplateMeasurement> measurementsByTemplate;

  TailorCustomer copyWith({
    String? name,
    String? phone,
    String? address,
    Map<String, TemplateMeasurement>? measurementsByTemplate,
  }) {
    return TailorCustomer(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      measurementsByTemplate:
          measurementsByTemplate ?? Map.of(this.measurementsByTemplate),
    );
  }
}

class TailorOrder {
  TailorOrder({
    required this.id,
    required this.customerName,
    required this.items,
    required this.orderDate,
    required this.dueDate,
    required this.status,
    required this.paymentMode,
    required this.advancePayment,
    required this.payments,
    required this.weightKg,
    required this.tailor,
    required this.priority,
    required this.notes,
  });

  final String id;
  final String customerName;
  final List<OrderTemplateItem> items;
  final DateTime orderDate;
  final DateTime dueDate;
  final String status;
  final String paymentMode;
  final int advancePayment;
  final List<OrderPayment> payments;
  final double weightKg;
  final String tailor;
  final bool priority;
  final String notes;

  int get amount => items.fold(0, (sum, item) => sum + item.total);

  int get balanceAmount => (amount - advancePayment).clamp(0, amount).toInt();

  bool get allTemplatesReady => items.every((item) => item.status == 'Ready');

  String get summary => items.map((item) => item.templateName).join(', ');

  TailorOrder copyWith({
    String? status,
    String? paymentMode,
    int? advancePayment,
    List<OrderPayment>? payments,
    List<OrderTemplateItem>? items,
  }) {
    return TailorOrder(
      id: id,
      customerName: customerName,
      items: items ?? this.items,
      orderDate: orderDate,
      dueDate: dueDate,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      advancePayment: advancePayment ?? this.advancePayment,
      payments: payments ?? this.payments,
      weightKg: weightKg,
      tailor: tailor,
      priority: priority,
      notes: notes,
    );
  }
}

class GarmentTemplate {
  GarmentTemplate({
    required this.name,
    required this.charges,
    required this.makerCharges,
    required this.fields,
  });

  final String name;
  final int charges;
  final int makerCharges;
  final List<String> fields;

  int get rate => charges + makerCharges;
}

class OrderPayment {
  OrderPayment({
    required this.amount,
    required this.mode,
    required this.paidAt,
    this.note,
    this.promiseDate,
  });

  final int amount;
  final String mode;
  final DateTime paidAt;
  final String? note;
  final DateTime? promiseDate;
}

class OrderTemplateItem {
  OrderTemplateItem({
    required this.templateName,
    required this.quantity,
    required this.status,
    required this.charges,
    required this.makerCharges,
    required this.measurementUpdatedAt,
    required this.measurements,
    Map<int, String>? assignedWorkerByUnit,
    Map<int, String>? workerPaymentStatusByUnit,
  })  : assignedWorkerByUnit = assignedWorkerByUnit ?? {},
        workerPaymentStatusByUnit = workerPaymentStatusByUnit ?? {};

  final String templateName;
  final int quantity;
  final String status;
  final int charges;
  final int makerCharges;
  final DateTime measurementUpdatedAt;
  final Map<String, String> measurements;
  final Map<int, String> assignedWorkerByUnit;
  final Map<int, String> workerPaymentStatusByUnit;

  int get rate => charges + makerCharges;

  int get total => rate * quantity;

  OrderTemplateItem copyWith({
    String? status,
    Map<int, String>? assignedWorkerByUnit,
    Map<int, String>? workerPaymentStatusByUnit,
  }) {
    return OrderTemplateItem(
      templateName: templateName,
      quantity: quantity,
      status: status ?? this.status,
      charges: charges,
      makerCharges: makerCharges,
      measurementUpdatedAt: measurementUpdatedAt,
      measurements: Map.of(measurements),
      assignedWorkerByUnit:
          assignedWorkerByUnit ?? Map.of(this.assignedWorkerByUnit),
      workerPaymentStatusByUnit:
          workerPaymentStatusByUnit ?? Map.of(this.workerPaymentStatusByUnit),
    );
  }
}

class TemplateMeasurement {
  TemplateMeasurement({
    required this.templateName,
    required this.updatedAt,
    required this.values,
  });

  final String templateName;
  final DateTime updatedAt;
  final Map<String, String> values;
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String _formatReceiptDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day/${months[date.month - 1]}/${date.year}';
}

String _formatReceiptDateTime(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final day = date.day.toString().padLeft(2, '0');
  final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$day-${months[date.month - 1]}-${date.year} '
      '$hour12:$minute $period';
}

String _formatShortDate(DateTime date) {
  return '${date.day}/${date.month}';
}

(
  Color,
  Color,
  Color,
  Color,
) _templateStatusColors(String status) {
  return switch (status.toLowerCase()) {
    'measurements' => (
        const Color(0xFFEAF6FF),
        const Color(0xFFD7ECFF),
        const Color(0xFF9ECDF5),
        const Color(0xFF17699C),
      ),
    'in stitching' => (
        const Color(0xFFFFF7D8),
        const Color(0xFFFFEDAA),
        const Color(0xFFEAC75F),
        const Color(0xFF8A6500),
      ),
    'ready' => (
        const Color(0xFFEAFBEF),
        const Color(0xFFD6F5DE),
        const Color(0xFF9DD8AA),
        const Color(0xFF176B32),
      ),
    'hold' => (
        const Color(0xFFFFEFEF),
        const Color(0xFFFFD8D8),
        const Color(0xFFE9A0A0),
        const Color(0xFFB3261E),
      ),
    _ => (
        const Color(0xFFFFFBF6),
        const Color(0xFFF6E7D8),
        const Color(0xFFEBD8C4),
        _brand,
      ),
  };
}

String _shortStatus(String status) {
  return switch (status) {
    'Measurements' => 'Measure',
    'In Stitching' => 'Stitch',
    _ => status,
  };
}
