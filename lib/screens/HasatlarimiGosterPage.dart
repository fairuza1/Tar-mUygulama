import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'DegerlendirPage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class HasatlarimiGosterPage extends StatefulWidget {
  const HasatlarimiGosterPage({Key? key}) : super(key: key);

  @override
  _HasatlarimiGosterPageState createState() => _HasatlarimiGosterPageState();
}

class _HasatlarimiGosterPageState extends State<HasatlarimiGosterPage> {
  List<dynamic> harvests = [];
  bool isLoading = true;
  int? userId;
  final Map<int, bool> _evaluatedHarvests = {};
  final ScrollController _scrollController = ScrollController();
  final double _elevation = 6;
  final Duration _animationDuration = const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _loadEvaluatedHarvests();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    setState(() {}); // AppBar'ın rengini dinamik olarak güncellemek için
  }

  Future<void> _loadEvaluatedHarvests() async {
    final prefs = await SharedPreferences.getInstance();
    final evaluatedString = prefs.getString('evaluatedHarvests');
    if (evaluatedString != null) {
      final evaluatedMap = json.decode(evaluatedString) as Map<String, dynamic>;
      setState(() {
        _evaluatedHarvests.addAll(
          evaluatedMap.map((key, value) => MapEntry(int.parse(key), value as bool)),
        );
      });
    }
  }

  Future<void> _saveEvaluatedHarvest(int harvestId) async {
    setState(() {
      _evaluatedHarvests[harvestId] = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'evaluatedHarvests',
      json.encode(_evaluatedHarvests.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');

    if (userId != null) {
      await _fetchHarvests(userId!);
    } else {
      setState(() => isLoading = false);
      _showSnackbar('Kullanıcı ID bulunamadı.', Colors.red);
    }
  }

  Future<void> _fetchHarvests(int userId) async {
    try {
      setState(() => isLoading = true);

      // Simüle edilmiş yükleme efekti (gerçek uygulamada kaldırın)
      await Future.delayed(const Duration(milliseconds: 800));

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/harvests/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final decodedResponse = utf8.decode(response.bodyBytes);

      setState(() {
        if (response.statusCode == 200) {
          harvests = json.decode(decodedResponse);
          // Simüle edilmiş veriler (gerçek uygulamada kaldırın)
          if (harvests.isEmpty) {
            harvests = List.generate(5, (index) => _generateMockHarvest(index));
          }
        } else {
          harvests = [];
        }
        isLoading = false;
      });

      if (response.statusCode == 204 || harvests.isEmpty) {
        _showSnackbar('Hiç hasat bulunamadı.', Colors.orange);
      } else if (response.statusCode != 200) {
        _showSnackbar(
            'Hasatlar yüklenemedi. Durum kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackbar('Hata: $e', Colors.red);
    }
  }

  // Simüle edilmiş hasat verisi (gerçek uygulamada kaldırın)
  Map<String, dynamic> _generateMockHarvest(int index) {
    final now = DateTime.now();
    final harvestDate = now.subtract(Duration(days: index * 7));
    return {
      'id': index + 1,
      'landName': 'Arazi ${index + 1}',
      'harvestDate': DateFormat('yyyy-MM-dd').format(harvestDate),
      'categoryName': ['Sebze', 'Meyve', 'Tahıl'][index % 3],
      'plantName': ['Domates', 'Elma', 'Buğday', 'Biber', 'Armut'][index % 5],
      'plantingAmount': (index + 1) * 100,
      'sowingId': index + 1000,
    };
  }

  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message, style: GoogleFonts.notoSans(color: Colors.white)),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget buildHarvestCard(Map<String, dynamic> harvest, int index) {
    final harvestId = harvest['id'] as int;
    final isEvaluated = _evaluatedHarvests[harvestId] ?? false;
    final plantName = harvest['plantName'] ?? 'Bilinmiyor';
    final categoryName = harvest['categoryName'] ?? 'Bilinmiyor';
    final harvestDate = harvest['harvestDate'] ?? 'Bilinmiyor';
    final formattedDate = _formatDate(harvestDate);

    return AnimatedPadding(
      duration: _animationDuration,
      padding: EdgeInsets.only(
        top: index == 0 ? 16 : 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade50,
                Colors.white,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: SvgPicture.asset(
                  'assets/leaf_corner.svg',
                  width: 80,
                  color: Colors.green.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            harvest['landName'] ?? 'Hasat $harvestId',
                            style: GoogleFonts.notoSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.green[900],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(categoryName),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            categoryName,
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, 'Hasat Tarihi', formattedDate),
                    _buildInfoRow(Icons.spa, 'Bitki', plantName),
                    _buildInfoRow(Icons.scale, 'Miktar', '${harvest['plantingAmount']} kg'),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        isEvaluated
                            ? _buildEvaluatedBadge()
                            : _buildEvaluateButton(harvest, harvestId),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluatedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 18, color: Colors.green.shade800),
          const SizedBox(width: 6),
          Text(
            'Değerlendirildi',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluateButton(Map<String, dynamic> harvest, int harvestId) {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DegerlendirPage(harvest: harvest),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
        await _saveEvaluatedHarvest(harvestId);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: Colors.green.shade300,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.rate_review, size: 18),
          const SizedBox(width: 6),
          Text(
            'Değerlendir',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sebze':
        return Colors.orange.shade600;
      case 'meyve':
        return Colors.red.shade400;
      case 'tahıl':
        return Colors.amber.shade700;
      default:
        return Colors.green.shade600;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    final appBarElevation = scrollOffset > 10 ? _elevation : 0.0;
    final appBarColor = scrollOffset > 10
        ? Colors.green.shade700
        : Colors.green.shade700.withOpacity(0.9);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: AnimatedOpacity(
          duration: _animationDuration,
          opacity: scrollOffset > 10 ? 1.0 : 0.0,
          child: Text('Hasatlarım', style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          )),
        ),
        centerTitle: true,
        elevation: appBarElevation,
        backgroundColor: appBarColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade700,
                Colors.green.shade600,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: userId != null ? () => _fetchHarvests(userId!) : null,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingScreen()
          : harvests.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            collapsedHeight: 80,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: AnimatedOpacity(
                duration: _animationDuration,
                opacity: scrollOffset > 10 ? 0.0 : 1.0,
                child: Text(
                  'Hasatlarım',
                  style: GoogleFonts.notoSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.green.shade700,
                      Colors.green.shade600,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => buildHarvestCard(harvests[index], index),
              childCount: harvests.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni hasat ekleme işlevi
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hasatlar Yükleniyor...',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/empty_state.svg',
            width: 200,
            color: Colors.green.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz Hasat Bulunamadı',
            style: GoogleFonts.notoSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Yeni hasat eklemek için alttaki butona basabilirsiniz',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Yeni hasat ekleme işlevi
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'Yeni Hasat Ekle',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
