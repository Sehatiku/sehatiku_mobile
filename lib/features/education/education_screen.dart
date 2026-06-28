import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/features/education/article_detail_screen.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dummy article data
// ─────────────────────────────────────────────────────────────────────────────

const _allArticles = [
  ArticleContent(
    icon: Icons.restaurant_rounded,
    category: 'NUTRISI',
    title: '5 Makanan Penurun Tekanan Darah Alami',
    readTime: '4 menit baca',
    author: 'Tim Edukasi Sehatiku',
    publishedDate: 'Senin, 23 Juni 2025',
    color: AppColors.primary,
    intro:
        'Tekanan darah tinggi atau hipertensi adalah kondisi yang dapat dikendalikan '
        'melalui pola makan yang tepat. Beberapa makanan terbukti secara ilmiah mampu '
        'membantu menurunkan tekanan darah secara alami, tanpa efek samping obat.',
    sections: [
      ArticleSection(
        heading: '1. Pisang',
        body:
            'Pisang kaya akan kalium, mineral yang membantu ginjal membuang natrium '
            'berlebih melalui urin sehingga tekanan darah ikut turun. Konsumsi 1–2 '
            'pisang per hari sudah cukup untuk memenuhi sekitar 10% kebutuhan kalium '
            'harian Anda.',
      ),
      ArticleSection(
        heading: '2. Bayam',
        body:
            'Bayam mengandung magnesium, kalium, dan nitrat alami. Nitrat diubah oleh '
            'tubuh menjadi oksida nitrat yang melebarkan pembuluh darah, sehingga '
            'aliran darah menjadi lebih lancar dan tekanan darah berkurang.',
      ),
      ArticleSection(
        heading: '3. Biji-bijian Utuh',
        body:
            'Oatmeal dan gandum utuh mengandung serat larut yang terbukti menurunkan '
            'tekanan sistolik. Penelitian menunjukkan konsumsi 3 porsi biji-bijian '
            'utuh per hari dapat menurunkan risiko hipertensi hingga 15%.',
      ),
      ArticleSection(
        heading: '4. Bawang Putih',
        body:
            'Allicin dalam bawang putih bersifat vasodilator alami. Studi meta-analisis '
            'menunjukkan suplemen bawang putih dapat menurunkan tekanan sistolik rata-rata '
            '5 mmHg pada penderita hipertensi.',
      ),
      ArticleSection(
        heading: '5. Beri-berian',
        body:
            'Blueberry, stroberi, dan ceri kaya flavonoid—khususnya antosianin—yang '
            'meningkatkan fleksibilitas pembuluh darah. Konsumsi rutin 3× seminggu '
            'dikaitkan dengan penurunan tekanan darah bermakna dalam 8 minggu.',
      ),
    ],
    closingNote:
        'Informasi ini bersifat edukatif dan bukan pengganti saran medis. '
        'Selalu konsultasikan perubahan pola makan Anda dengan dokter atau ahli gizi.',
  ),
  ArticleContent(
    icon: Icons.directions_walk_rounded,
    category: 'AKTIVITAS',
    title: 'Olahraga Aman untuk Penderita Diabetes',
    readTime: '6 menit baca',
    author: 'Tim Edukasi Sehatiku',
    publishedDate: 'Rabu, 18 Juni 2025',
    color: AppColors.green,
    intro:
        'Olahraga adalah salah satu cara paling efektif untuk mengontrol gula darah. '
        'Aktivitas fisik membuat sel tubuh lebih sensitif terhadap insulin sehingga '
        'glukosa dapat masuk ke sel dengan lebih mudah. Namun, penderita diabetes '
        'perlu memilih jenis dan intensitas olahraga yang tepat agar aman.',
    sections: [
      ArticleSection(
        heading: 'Kenapa olahraga penting?',
        body:
            'Saat berolahraga, otot menggunakan glukosa sebagai bahan bakar sehingga '
            'kadar gula darah turun secara alami. Efek ini berlangsung hingga 24 jam '
            'setelah latihan. Olahraga rutin juga membantu menurunkan berat badan, '
            'tekanan darah, dan kadar kolesterol.',
      ),
      ArticleSection(
        heading: 'Olahraga yang direkomendasikan',
        body:
            'Jalan kaki 30 menit minimal 5 hari seminggu adalah pilihan terbaik untuk '
            'pemula. Selain itu, bersepeda santai, berenang, senam aerobik ringan, '
            'dan yoga cocok dilakukan secara rutin. Kombinasikan latihan aerobik dengan '
            'latihan kekuatan (resistance training) 2–3× seminggu untuk hasil optimal.',
      ),
      ArticleSection(
        heading: 'Hal yang perlu diperhatikan',
        body:
            'Periksa gula darah sebelum berolahraga. Jika di bawah 100 mg/dL, konsumsi '
            'snack dulu untuk mencegah hipoglikemia. Selalu bawa permen atau jus untuk '
            'berjaga-jaga. Hindari olahraga saat gula darah di atas 250 mg/dL dan ada '
            'keton dalam urin karena dapat memperburuk kondisi.',
      ),
      ArticleSection(
        heading: 'Durasi dan progres',
        body:
            'Mulailah dengan 10–15 menit per sesi dan tingkatkan secara bertahap. '
            'Target akhir adalah 150 menit aktivitas sedang per minggu sesuai panduan '
            'ADA (American Diabetes Association). Dengarkan tubuh Anda dan istirahat '
            'jika merasa pusing atau sesak napas.',
      ),
    ],
    closingNote:
        'Konsultasikan program olahraga Anda dengan dokter sebelum memulai, '
        'terutama jika Anda memiliki komplikasi seperti neuropati atau retinopati.',
  ),
  ArticleContent(
    icon: Icons.medication_rounded,
    category: 'OBAT',
    title: 'Pentingnya Minum Obat Tepat Waktu',
    readTime: '3 menit baca',
    author: 'Tim Edukasi Sehatiku',
    publishedDate: 'Jumat, 13 Juni 2025',
    color: AppColors.violet,
    intro:
        'Banyak pasien diabetes dan hipertensi yang menghentikan atau melewatkan '
        'obat saat merasa kondisinya sudah membaik. Kebiasaan ini justru berbahaya '
        'dan dapat memicu komplikasi serius.',
    sections: [
      ArticleSection(
        heading: 'Mengapa konsistensi itu krusial?',
        body:
            'Obat antihipertensi dan antidiabetik bekerja dengan menjaga kadar zat aktif '
            'dalam darah tetap stabil. Melewatkan dosis menyebabkan kadar ini turun '
            'drastis, lalu naik kembali secara tiba-tiba saat obat diminum lagi. '
            'Fluktuasi ini merusak pembuluh darah dan organ target dalam jangka panjang.',
      ),
      ArticleSection(
        heading: 'Efek melewatkan obat',
        body:
            'Satu kali melewatkan obat antihipertensi dapat menyebabkan lonjakan '
            'tekanan darah hingga 20 mmHg. Untuk obat diabetes, risiko hiperglikemia '
            'rebound (kadar gula melonjak kembali) bisa berlangsung hingga 48 jam '
            'setelah dosis terlewat.',
      ),
      ArticleSection(
        heading: 'Tips minum obat tepat waktu',
        body:
            'Gunakan alarm di ponsel untuk pengingat. Simpan obat di tempat yang mudah '
            'terlihat seperti meja makan. Gunakan kotak pil mingguan agar Anda mudah '
            'mengecek apakah dosis hari ini sudah diminum. Catat kepatuhan minum obat '
            'di aplikasi Sehatiku setiap hari.',
      ),
    ],
    closingNote:
        'Jangan mengubah dosis atau menghentikan obat tanpa konsultasi dokter, '
        'meskipun kondisi terasa sudah membaik.',
  ),
  ArticleContent(
    icon: Icons.bedtime_rounded,
    category: 'TIDUR & STRES',
    title: 'Cara Tidur Berkualitas untuk Kontrol Gula',
    readTime: '5 menit baca',
    author: 'Tim Edukasi Sehatiku',
    publishedDate: 'Selasa, 10 Juni 2025',
    color: AppColors.orange,
    intro:
        'Kualitas tidur yang buruk secara langsung memengaruhi resistensi insulin '
        'dan kadar kortisol. Kurang tidur hanya 2 hari saja sudah cukup untuk '
        'meningkatkan kadar gula darah puasa secara signifikan.',
    sections: [
      ArticleSection(
        heading: 'Bagaimana tidur memengaruhi gula darah?',
        body:
            'Saat tidur kurang dari 6 jam, tubuh memproduksi lebih banyak kortisol '
            '(hormon stres) dan ghrelin (hormon lapar). Kortisol meningkatkan '
            'produksi glukosa oleh hati, sementara ghrelin mendorong konsumsi '
            'makanan tinggi karbohidrat keesokan harinya.',
      ),
      ArticleSection(
        heading: 'Durasi tidur yang ideal',
        body:
            'Orang dewasa membutuhkan 7–9 jam tidur per malam. Penderita diabetes '
            'sebaiknya menjaga konsistensi jam tidur dan bangun, bahkan di akhir '
            'pekan. Tidur siang singkat (20–30 menit) boleh dilakukan asal tidak '
            'mengganggu tidur malam.',
      ),
      ArticleSection(
        heading: 'Tips hygiene tidur',
        body:
            'Hindari layar ponsel atau laptop minimal 1 jam sebelum tidur karena '
            'cahaya biru menekan produksi melatonin. Jaga suhu kamar antara 18–22°C. '
            'Hindari kafein setelah pukul 14.00. Coba teknik relaksasi seperti '
            'pernapasan 4-7-8 atau meditasi ringan sebelum tidur untuk menurunkan '
            'kadar kortisol.',
      ),
      ArticleSection(
        heading: 'Stres dan gula darah',
        body:
            'Stres emosional memicu respons fight-or-flight yang melepaskan glukosa '
            'cadangan ke aliran darah. Kelola stres dengan olahraga ringan, jurnal '
            'harian, atau berbicara dengan orang terdekat. Aplikasi Sehatiku '
            'mencatat indeks stres harian Anda agar pola ini terlihat dari waktu ke waktu.',
      ),
    ],
    closingNote:
        'Jika Anda mengalami gangguan tidur kronis seperti sleep apnea, '
        'segera konsultasikan dengan dokter karena kondisi ini berkaitan erat '
        'dengan resistensi insulin.',
  ),
  ArticleContent(
    icon: Icons.monitor_weight_rounded,
    category: 'BERAT BADAN',
    title: 'Mengapa Berat Badan Ideal Penting bagi Diabetisi?',
    readTime: '5 menit baca',
    author: 'Tim Edukasi Sehatiku',
    publishedDate: 'Kamis, 5 Juni 2025',
    color: AppColors.cyan,
    intro:
        'Kelebihan berat badan—terutama lemak visceral di area perut—adalah salah '
        'satu faktor risiko terbesar diabetes tipe 2 dan hipertensi. Penurunan '
        'berat badan sebesar 5–10% saja sudah memberikan manfaat kesehatan yang nyata.',
    sections: [
      ArticleSection(
        heading: 'Kaitan lemak perut dan insulin',
        body:
            'Lemak visceral melepaskan asam lemak bebas dan sitokin inflamasi yang '
            'mengganggu kerja insulin di sel otot dan hati. Hasilnya, tubuh membutuhkan '
            'lebih banyak insulin untuk efek yang sama—inilah yang disebut resistensi insulin.',
      ),
      ArticleSection(
        heading: 'Target penurunan berat badan yang realistis',
        body:
            'Turunkan 0,5–1 kg per minggu dengan defisit kalori 500 kkal/hari. '
            'Cara ini lebih aman dan lebih mudah dipertahankan dibanding diet '
            'ketat jangka pendek. Hindari diet ekstrem karena dapat memicu '
            'hipoglikemia, terutama jika Anda sedang mengonsumsi obat diabetes.',
      ),
      ArticleSection(
        heading: 'Strategi makan cerdas',
        body:
            'Gunakan metode piring (plate method): ½ piring sayuran non-tepung, '
            '¼ piring protein tanpa lemak, ¼ piring karbohidrat kompleks. '
            'Makan perlahan dan berhenti saat 80% kenyang. Catat asupan makanan '
            'Anda di fitur Catatan Sehatiku untuk memantau pola makan.',
      ),
    ],
    closingNote:
        'Program penurunan berat badan untuk penderita diabetes sebaiknya '
        'dilakukan di bawah pengawasan dokter atau ahli gizi agar dosis obat '
        'dapat disesuaikan secara berkala.',
  ),
  ArticleContent(
    icon: Icons.water_drop_rounded,
    category: 'NUTRISI',
    title: 'Mengenal Indeks Glikemik pada Makanan',
    readTime: '7 menit baca',
    author: 'Tim Edukasi Sehatiku',
    publishedDate: 'Senin, 2 Juni 2025',
    color: AppColors.amber,
    intro:
        'Tidak semua karbohidrat dicerna pada kecepatan yang sama. Indeks Glikemik (IG) '
        'adalah skala 0–100 yang menunjukkan seberapa cepat suatu makanan menaikkan '
        'gula darah dibandingkan glukosa murni.',
    sections: [
      ArticleSection(
        heading: 'Makanan IG rendah (di bawah 55)',
        body:
            'Oatmeal, kentang rebus dingin, beras merah, kacang-kacangan, dan sebagian '
            'besar sayuran non-tepung masuk kategori ini. Makanan IG rendah dicerna '
            'perlahan sehingga gula darah naik secara bertahap dan stabil.',
      ),
      ArticleSection(
        heading: 'Makanan IG tinggi (di atas 70)',
        body:
            'Nasi putih pulen, roti tawar putih, minuman manis, dan kentang goreng '
            'termasuk IG tinggi. Konsumsi makanan ini menyebabkan lonjakan gula darah '
            'cepat, diikuti penurunan tajam yang memicu rasa lapar kembali.',
      ),
      ArticleSection(
        heading: 'Cara menurunkan IG makanan',
        body:
            'Tambahkan cuka atau perasan jeruk nipis ke nasi dapat menurunkan IG-nya. '
            'Memasak pasta al-dente (sedikit keras) memiliki IG lebih rendah dari '
            'pasta yang dimasak terlalu lembut. Nasi yang didinginkan lalu dipanaskan '
            'kembali mengandung lebih banyak pati resistan yang dicerna lebih lambat.',
      ),
      ArticleSection(
        heading: 'Beban Glikemik (BG) lebih penting dari IG',
        body:
            'BG memperhitungkan ukuran porsi. Semangka memiliki IG tinggi (72) namun '
            'BG rendah karena kandungan karbohidratnya sedikit per sajian. '
            'Untuk kontrol gula yang optimal, perhatikan kombinasi IG dan ukuran porsi.',
      ),
    ],
    closingNote:
        'Tabel IG dapat bervariasi tergantung cara memasak, kematangan, dan '
        'kombinasi makanan. Konsultasikan dengan ahli gizi untuk rencana makan '
        'yang dipersonalisasi.',
  ),
  ArticleContent(
    icon: Icons.favorite_rounded,
    category: 'HIPERTENSI',
    title: 'Memahami Angka Tekanan Darah Anda',
    readTime: '4 menit baca',
    author: 'Tim Edukasi Sehatiku',
    publishedDate: 'Jumat, 30 Mei 2025',
    color: AppColors.pink,
    intro:
        'Tekanan darah diukur dalam dua angka: sistolik (angka atas) dan diastolik '
        '(angka bawah) dalam satuan mmHg. Memahami artinya adalah langkah pertama '
        'dalam mengelola hipertensi.',
    sections: [
      ArticleSection(
        heading: 'Apa arti dua angka tersebut?',
        body:
            'Sistolik menunjukkan tekanan saat jantung berkontraksi dan memompa darah. '
            'Diastolik menunjukkan tekanan saat jantung beristirahat di antara detak. '
            'Keduanya penting: sistolik tinggi merusak pembuluh arteri, diastolik '
            'tinggi menandakan beban kerja jantung yang terus-menerus.',
      ),
      ArticleSection(
        heading: 'Klasifikasi tekanan darah',
        body:
            'Normal: di bawah 120/80 mmHg. Elevated (pre-hipertensi): 120–129/<80. '
            'Hipertensi Stadium 1: 130–139/80–89. Hipertensi Stadium 2: ≥140/≥90. '
            'Krisis hipertensi: di atas 180/120—segera ke IGD.',
      ),
      ArticleSection(
        heading: 'Kapan dan bagaimana mengukur?',
        body:
            'Ukur di pagi hari sebelum minum obat dan aktivitas berat, serta malam '
            'hari sebelum tidur. Duduk tenang 5 menit sebelum pengukuran, kaki '
            'menapak lantai, lengan setinggi jantung. Catat dua pengukuran berturut-turut '
            'dan ambil rata-ratanya.',
      ),
      ArticleSection(
        heading: 'Target tekanan darah untuk penderita diabetes',
        body:
            'Panduan terkini merekomendasikan target <130/80 mmHg untuk pasien '
            'diabetes yang disertai hipertensi, karena kombinasi keduanya '
            'meningkatkan risiko penyakit jantung dan ginjal secara berlipat.',
      ),
    ],
    closingNote:
        'Pengukuran tekanan darah di rumah dapat memberikan gambaran yang lebih '
        'akurat daripada pengukuran tunggal di klinik. Bawa catatan pengukuran '
        'Anda ke setiap kunjungan dokter.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Filter config
// ─────────────────────────────────────────────────────────────────────────────

/// Maps each filter label to the article category tags it should show.
const _filterTags = {
  'Semua': <String>[],            // empty = show all
  'Diabetes': ['AKTIVITAS', 'OBAT', 'TIDUR & STRES', 'BERAT BADAN', 'NUTRISI'],
  'Hipertensi': ['NUTRISI', 'OBAT', 'BERAT BADAN', 'HIPERTENSI'],
  'Nutrisi': ['NUTRISI'],
};

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class EducationScreen extends StatelessWidget {
  const EducationScreen({
    super.key,
    required this.onBack,
    required this.selectedFilter,
    required this.onFilter,
    required this.onAction,
  });

  final VoidCallback onBack;
  final int selectedFilter;
  final ValueChanged<int> onFilter;
  final ValueChanged<String> onAction;

  static const _filters = ['Semua', 'Diabetes', 'Hipertensi', 'Nutrisi'];

  List<ArticleContent> _filtered(int index) {
    final label = _filters[index];
    final tags = _filterTags[label]!;
    if (tags.isEmpty) return _allArticles;
    return _allArticles.where((a) => tags.contains(a.category)).toList();
  }

  void _openArticle(BuildContext context, ArticleContent article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArticleDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered(selectedFilter);

    return DetailScaffold(
      title: 'Edukasi Kesehatan',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips ─────────────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _filters.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: PillTab(
                      label: _filters[i],
                      selected: selectedFilter == i,
                      compact: true,
                      onTap: () => onFilter(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Featured article banner ───────────────────────────────────────
          GestureDetector(
            onTap: () => _openArticle(context, _allArticles[0]),
            child: GradientPanel(
              radius: 24,
              colors: const [AppColors.primary, AppColors.green],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Pilihan Hari Ini',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mengelola Gula Darah di Rumah dengan Tepat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: const Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Color(0xD9FFFFFF),
                          size: 15,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '5 menit baca',
                          style: TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 12.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xD9FFFFFF),
                          size: 15,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Baca sekarang',
                          style: TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // ── Article list ─────────────────────────────────────────────────
          const SectionTitle(title: 'Artikel untuk Anda'),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  'Tidak ada artikel untuk kategori ini.',
                  style: TextStyle(color: AppColors.of(context).muted),
                ),
              ),
            )
          else
            for (final article in filtered)
              ArticleTile(
                icon: article.icon,
                category: article.category,
                title: article.title,
                time: article.readTime,
                color: article.color,
                onTap: () => _openArticle(context, article),
              ),
        ],
      ),
    );
  }
}
