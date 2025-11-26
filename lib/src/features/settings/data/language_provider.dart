import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- 1. MODERN NOTIFIER (Replaces StateProvider) ---
class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    return 'en'; // Default language is English
  }

  // Method to change language
  void setLanguage(String lang) {
    state = lang;
  }
}

// The Provider definition
final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});

// --- 2. STRING TRANSLATIONS ---
class AppStrings {
  static String get(String key, String lang) {
    if (lang == 'bn') return _bn[key] ?? key;
    return _en[key] ?? key;
  }

  static final Map<String, String> _en = {
    // General
    'app_title': 'MyKhata',
    'settings': 'Settings',
    'save': 'SAVE',
    'update': 'UPDATE',
    'edit': 'Edit',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'yes': 'Yes',
    'no': 'No',
    'warning': 'Warning!',
    'error': 'Error',
    
    // Dashboard
    'cash_in_hand': 'CASH IN HAND',
    'receive': 'Receive (Pabo)',
    'pay': 'Pay (Dibo)',
    'add_new': 'Add New',
    'history': 'History',
    'contacts': 'Contacts',
    'reports': 'Reports',
    'analytics': 'Analytics',
    
    // Transactions
    'all_history': 'All History',
    'no_transactions': 'No transactions found.',
    'search_history': 'Search note or amount...',
    'cash_in': 'Cash In (Joma)',
    'cash_out': 'Cash Out (Khoroch)',
    'amount': 'Amount (৳)',
    'note': 'Note (e.g., Sales, Lunch)',
    'date': 'Date',
    'add_transaction': 'Add Transaction',
    'edit_transaction': 'Edit Transaction',
    'category': 'Category',
    'split': 'Split',
    'split_breakdown': 'Split Breakdown',
    'total_amount': 'Total Amount',
    
    // Parties (Contacts)
    'customers_suppliers': 'Customers & Suppliers',
    'no_contacts': 'No contacts found.',
    'search_contacts': 'Search name or mobile...',
    'add_contact': 'Add Contact',
    'edit_contact': 'Edit Contact',
    'save_contact': 'SAVE CONTACT',
    'name': 'Name',
    'mobile': 'Mobile Number',
    'customer_type': 'Customer (Pabo)',
    'supplier_type': 'Supplier (Dibo)',
    'ledger_history': 'Ledger History',
    'current_balance': 'Current Balance',
    'gave_money': 'GAVE MONEY\n(DILAM)',
    'got_money': 'GOT MONEY\n(PELAM)',
    'add_due': 'Add Due (Baki)',
    'receive_due': 'Receive Cash (Joma)',
    'gave': 'Gave',
    'got': 'Got',
    
    // Delete Dialogs
    'delete_confirm_title': 'Delete?',
    'delete_txn_msg': 'Are you sure you want to remove this entry?',
    'delete_party_msg': 'This will delete the contact AND ALL their history.',
    'delete_all': 'DELETE ALL',

    // Backup
    'backup': 'Backup Data',
    'restore': 'Restore Data',
    'restore_msg': 'This will DELETE all current data. Are you sure?',
    'download_pdf': 'DOWNLOAD PDF',

    // Analytics
    'expense_breakdown': 'Expense Breakdown',
    'no_expenses': 'No expenses to show.',

    // Transfer
    'transfer': 'Transfer',
    'transfer_fund': 'Transfer Funds',
    'from_wallet': 'From Wallet',
    'to_wallet': 'To Wallet',
    'transfer_success': 'Transfer Successful!',
    'same_wallet_error': 'Source and Destination cannot be same.',

    // Bazar (Shopping List)
    'bazar': 'Bazar',
    'no_bazar': 'No bazar records found.',
    'search_bazar': 'Search item name or price...',
    'add_bazar': 'Add Bazar',
    'edit_bazar': 'Edit Bazar',
    'save_bazar': 'SAVE BAZAR',
    'item_name': 'Item Name',
    'estimated_cost': 'Estimated Cost (৳)',
    'bazar_history': 'Bazar History',
    'bazar_list': 'Bazar List',
    'checkout': 'Checkout',
    'checkout_bought_items': 'Checkout Bought Items',
    'checkout_msg': 'This will add an Expense to your ledger and remove the bought items from this list.',

    // Bike
    'bike': 'Bike',
    'no_bike_records': 'No bike records found.',
    'search_bike': 'Search description or amount...',
    'add_bike_record': 'Add Bike Record',
    'edit_bike_record': 'Edit Bike Record',
    'save_bike_record': 'SAVE BIKE RECORD',
    'description': 'Description',
    'amount_spent': 'Amount Spent (৳)',
    'bike_history': 'Bike History',
    'bike_records': 'Bike Records',
    'add_bike': 'Add Bike',
    'edit_bike': 'Edit Bike',
    'save_bike': 'SAVE BIKE',
    'bike_name': 'Bike Name',
    'bike_number': 'Bike Number',
    'bike_list': 'Bike List',

    // --- NEW: Budgeting ---
    'budget_title': 'Monthly Budget',
    'set_budget': 'Set Budget',
    'limit_amount': 'Limit Amount (৳)',
    'spent': 'Spent',
    'limit': 'Limit',
    'near_limit': '⚠️ Near Budget Limit!',
    'over_budget': '🚨 Over Budget!',
    'no_categories': 'No expense categories found.',

    // --- NEW: Recurring Bills ---
    'recurring_title': 'Recurring Bills & Subscriptions',
    'no_recurring': 'No recurring bills set up.\nAdd your Rent, Internet, or Tuition fees.',
    'add_bill': 'Add Bill',
    'bill_name': 'Bill Name (e.g. Rent)',
    'day_of_month': 'Day of Month (1-28)',
    'due_today': 'Due Today!',
    'pay_now': 'PAY NOW',
    'marked_paid': 'Marked as Paid!',
    
    // --- NEW: Savings ---
    'savings_title': 'Savings Goals',
    'no_goals': 'No goals yet.\nStart saving for a Dream!',
    'new_goal': 'New Goal',
    'set_goal': 'Set New Goal',
    'goal_name': 'Goal Name (e.g. Laptop)',
    'target_amount': 'Target Amount',
    'target_date': 'Target Date (Optional)',
    'create_goal': 'Create Goal',
    'goal_reached': 'Goal Reached! 🎉',
    'add_savings': 'Add Savings',
    'deposit': 'Deposit',
    'deduct_wallet': 'Deduct from Wallet Balance?',
    'saved': 'Saved',
    'target': 'Target',
  };

  static final Map<String, String> _bn = {
    // General
    'app_title': 'মাই খাতা',
    'settings': 'সেটিংস',
    'save': 'সেভ করুন',
    'update': 'আপডেট করুন',
    'edit': 'এডিট',
    'delete': 'ডিলিট',
    'cancel': 'বাতিল',
    'yes': 'হ্যাঁ',
    'no': 'না',
    'warning': 'সতর্কতা!',
    'error': 'ত্রুটি',

    // Dashboard
    'cash_in_hand': 'হাতে আছে',
    'receive': 'পাবো (Receive)',
    'pay': 'দিবো (Pay)',
    'add_new': 'নতুন যোগ করুন',
    'history': 'লেনদেন ইতিহাস',
    'contacts': 'কাস্টমার ও মহাজন',
    'reports': 'রিপোর্ট',
    'analytics': 'বিশ্লেষণ',

    // Transactions
    'all_history': 'সকল লেনদেন',
    'no_transactions': 'কোনো লেনদেন পাওয়া যায়নি',
    'search_history': 'বিবরণ বা টাকার পরিমাণ খুঁজুন...',
    'cash_in': 'জমা (Cash In)',
    'cash_out': 'খরচ (Cash Out)',
    'amount': 'টাকার পরিমাণ (৳)',
    'note': 'বিবরণ (যেমন: বিক্রি, নাস্তা)',
    'date': 'তারিখ',
    'add_transaction': 'লেনদেন যোগ করুন',
    'edit_transaction': 'লেনদেন পরিবর্তন করুন',
    'category': 'ক্যাটাগরি',
    'split': 'ভাগ (Split)',
    'split_breakdown': 'খরচের ভাগ',
    'total_amount': 'মোট টাকা',

    // Parties (Contacts)
    'customers_suppliers': 'কাস্টমার ও মহাজন',
    'no_contacts': 'কোনো কন্টাক্ট নেই',
    'search_contacts': 'নাম বা মোবাইল নম্বর খুঁজুন...',
    'add_contact': 'নতুন কন্টাক্ট',
    'edit_contact': 'কন্টাক্ট পরিবর্তন',
    'save_contact': 'সেভ করুন',
    'name': 'নাম',
    'mobile': 'মোবাইল নম্বর',
    'customer_type': 'কাস্টমার (পাবো)',
    'supplier_type': 'মহাজন (দিবো)',
    'ledger_history': 'লেনদেনের খাতা',
    'current_balance': 'বর্তমান জের',
    'gave_money': 'টাকা দিলাম\n(বাকি)',
    'got_money': 'টাকা পেলাম\n(জমা)',
    'add_due': 'বাকি দিলাম',
    'receive_due': 'বাকি পেলাম',
    'gave': 'দিলাম',
    'got': 'পেলাম',

    // Delete Dialogs
    'delete_confirm_title': 'ডিলিট করবেন?',
    'delete_txn_msg': 'আপনি কি এই লেনদেনটি মুছে ফেলতে চান?',
    'delete_party_msg': 'এটি কন্টাক্ট এবং তার সব লেনদেন মুছে ফেলবে।',
    'delete_all': 'সব ডিলিট করুন',

    // Backup
    'backup': 'ব্যাকআপ রাখুন',
    'restore': 'ডাটা ফেরত আনুন',
    'restore_msg': 'এটি বর্তমান সব ডাটা মুছে ফেলবে। আপনি কি নিশ্চিত?',
    'download_pdf': 'পিডিএফ ডাউনলোড',

    // Analytics
    'expense_breakdown': 'খরচের হিসাব',
    'no_expenses': 'কোনো খরচ পাওয়া যায়নি',

    // Transfer
    'transfer': 'ট্রান্সফার',
    'transfer_fund': 'টাকা ট্রান্সফার',
    'from_wallet': 'থেকে (From)',
    'to_wallet': 'তে (To)',
    'transfer_success': 'ট্রান্সফার সফল হয়েছে!',
    'same_wallet_error': 'একই ওয়ালেটে ট্রান্সফার করা যাবে না',

    // Bazar (Shopping List)
    'bazar': 'বাজার',
    'no_bazar': 'কোনো বাজার রেকর্ড নেই',
    'search_bazar': 'আইটেম বা দাম খুঁজুন...',
    'add_bazar': 'বাজার যোগ করুন',
    'edit_bazar': 'বাজার পরিবর্তন করুন',
    'save_bazar': 'সেভ করুন',
    'item_name': 'আইটেমের নাম',
    'estimated_cost': 'আনুমানিক খরচ (৳)',
    'bazar_history': 'বাজারের ইতিহাস',
    'bazar_list': 'বাজার তালিকা',
    'checkout': 'চেকআউট',
    'checkout_bought_items': 'কেনা আইটেম চেকআউট',
    'checkout_msg': 'এটি আপনার খাতায় খরচ যোগ করবে এবং কেনা আইটেমগুলো মুছে ফেলবে।',

    // Bike
    'bike': 'বাইক',
    'no_bike_records': 'কোনো বাইক রেকর্ড নেই',
    'search_bike': 'বিবরণ বা টাকার পরিমাণ খুঁজুন...',
    'add_bike_record': 'বাইক রেকর্ড যোগ করুন',
    'edit_bike_record': 'বাইক রেকর্ড পরিবর্তন করুন',
    'save_bike_record': 'সেভ করুন',
    'description': 'বিবরণ',
    'amount_spent': 'খরচের পরিমাণ (৳)',
    'bike_history': 'বাইক ইতিহাস',
    'bike_records': 'বাইক রেকর্ড',
    'add_bike': 'বাইক যোগ করুন',
    'edit_bike': 'বাইক পরিবর্তন করুন',
    'save_bike': 'সেভ করুন',
    'bike_name': 'বাইকের নাম',
    'bike_number': 'বাইক নম্বর',
    'bike_list': 'বাইক তালিকা',

    // --- NEW: Budgeting ---
    'budget_title': 'মাসিক বাজেট',
    'set_budget': 'বাজেট সেট করুন',
    'limit_amount': 'সর্বোচ্চ সীমা (৳)',
    'spent': 'খরচ হয়েছে',
    'limit': 'সীমা',
    'near_limit': '⚠️ বাজেটের কাছাকাছি!',
    'over_budget': '🚨 বাজেট অতিক্রম করেছে!',
    'no_categories': 'কোনো খরচের ক্যাটাগরি পাওয়া যায়নি',

    // --- NEW: Recurring Bills ---
    'recurring_title': 'নিয়মিত বিল ও সাবস্ক্রিপশন',
    'no_recurring': 'কোনো নিয়মিত বিল নেই।\nভাড়া, ইন্টারনেট বা টিউশন ফি যোগ করুন।',
    'add_bill': 'বিল যোগ করুন',
    'bill_name': 'বিলের নাম (যেমন: ভাড়া)',
    'day_of_month': 'মাসের তারিখ (১-২৮)',
    'due_today': 'আজ দিতে হবে!',
    'pay_now': 'পরিশোধ করুন',
    'marked_paid': 'পরিশোধিত হিসেবে মার্ক করা হয়েছে!',

    // --- NEW: Savings ---
    'savings_title': 'সঞ্চয়ের লক্ষ্য',
    'no_goals': 'কোনো লক্ষ্য নেই।\nস্বপ্নের জন্য সঞ্চয় শুরু করুন!',
    'new_goal': 'নতুন লক্ষ্য',
    'set_goal': 'লক্ষ্য ঠিক করুন',
    'goal_name': 'লক্ষ্যের নাম (যেমন: ল্যাপটপ)',
    'target_amount': 'লক্ষ্য পরিমাণ',
    'target_date': 'লক্ষ্য তারিখ (ঐচ্ছিক)',
    'create_goal': 'লক্ষ্য তৈরি করুন',
    'goal_reached': 'লক্ষ্য অর্জিত হয়েছে! 🎉',
    'add_savings': 'সঞ্চয় জমা করুন',
    'deposit': 'জমা দিন',
    'deduct_wallet': 'ওয়ালেট থেকে কাটবেন?',
    'saved': 'জমা হয়েছে',
    'target': 'লক্ষ্য',
  };
}