import 'package:agor/services/database.dart';
import 'package:agor/services/notification_services.dart';
import 'package:agor/theme/color.dart';
import 'package:agor/widget/fatura.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  ValueNotifier<String> balance = ValueNotifier("0");
  ValueNotifier<List<Map<String, dynamic>>> transactions = ValueNotifier([]);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    String uid = await CosmosFirebase.getUID();
    List userData = await CosmosFirebase.get('users/"$uid"', true);

    if (userData.length > 10) {
      balance.value = userData[10];
      balance.notifyListeners();
    }

    // Fatura geçmişini yükle
    List transactionData = await CosmosFirebase.getOnce("transactions/$uid");
    List<Map<String, dynamic>> loadedTransactions = [];

    for (var transaction in transactionData) {
      if (transaction is List && transaction.length >= 4) {
        loadedTransactions.add({
          "id": transaction[0],
          "amount": transaction[1],
          "date": transaction[2],
          "type": transaction[3],
        });
      }
    }

    transactions.value = loadedTransactions;
    transactions.notifyListeners();
  }

  Future<void> _addBalance(String amount) async {
    String uid = await CosmosFirebase.getUID();
    List userData = await CosmosFirebase.get('users/"$uid"', true);

    int currentBalance =
        int.tryParse(userData.length > 10 ? userData[10] : "0") ?? 0;
    int addedAmount = int.tryParse(amount) ?? 0;
    int newBalance = currentBalance + addedAmount;

    if (userData.length <= 10) {
      userData.add(newBalance.toString());
    } else {
      userData[10] = newBalance.toString();
    }

    await CosmosFirebase.add(
      reference: "users",
      tag: uid,
      value: userData,
    );

    // İşlem kaydı ekle
    String transactionId = DateTime.now().millisecondsSinceEpoch.toString();
    await CosmosFirebase.add(
      reference: "transactions/$uid",
      tag: transactionId,
      value: [
        transactionId,
        amount,
        CosmosTime.getNowTimeString(),
        "deposit", // işlem tipi: yatırma
      ],
    );

    balance.value = newBalance.toString();
    balance.notifyListeners();

    // Ana sayfadaki cüzdan değerini güncelle
    Database.profileWallet.value = newBalance.toString();

    // Bakiye eklendiğinde bildirim gönder
    await NotificationServices.sendWalletNotification(
      userId: uid,
      amount: amount,
      operation: "add",
    );

    await _loadWalletData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: defaultColor,
        content: Text(
          '$amount TL bakiyenize eklendi',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cüzdanım',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: defaultColor,
          labelColor: defaultColor,
          unselectedLabelColor: textColor.withOpacity(0.5),
          tabs: [
            Tab(text: 'Bakiye'),
            Tab(text: 'Faturalar'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([balance, transactions]),
        builder: (context, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Bakiye Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bakiye Kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            defaultColor,
                            defaultColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: defaultColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mevcut Bakiye',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${balance.value} TL',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Dert Ortağım',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bakiye Yükleme Seçenekleri
                    Text(
                      'Bakiye Yükle',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bakiye Yükleme Butonları
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildAmountButton('100'),
                        _buildAmountButton('500'),
                        _buildAmountButton('1000'),
                        _buildAmountButton('1500'),
                        _buildAmountButton('2000'),
                        _buildCustomAmountButton(),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Bilgi Kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: defaultColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bilgi',
                                style: GoogleFonts.poppins(
                                  color: defaultColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Yüklediğiniz bakiye ile dinleyicilere bağış yapabilir veya özel görüşmeler gerçekleştirebilirsiniz.',
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Faturalar Tab
              transactions.value.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: textColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz işlem geçmişiniz bulunmuyor',
                            style: GoogleFonts.poppins(
                              color: textColor.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.value.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions.value[index];
                        return FaturaWidget(
                          amount: transaction["amount"],
                          date: transaction["date"],
                          type: transaction["type"],
                          id: transaction["id"],
                        );
                      },
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAmountButton(String amount) {
    return GestureDetector(
      onTap: () => _addBalance(amount),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 22,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            '$amount TL',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAmountButton() {
    return GestureDetector(
      onTap: () {
        _showCustomAmountDialog();
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 22,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: defaultColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: defaultColor.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            'Diğer',
            style: GoogleFonts.poppins(
              color: defaultColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomAmountDialog() {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cColor,
        title: Text(
          'Özel Tutar',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Tutar giriniz (TL)',
            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
            filled: true,
            fillColor: bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            prefixIcon: Icon(Icons.attach_money, color: defaultColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: defaultColor,
            ),
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                Navigator.pop(context);
                _addBalance(amountController.text);
              }
            },
            child: Text(
              'Yükle',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
