import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class ArticleSection {
  const ArticleSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

class ArticleContent {
  const ArticleContent({
    required this.icon,
    required this.category,
    required this.title,
    required this.readTime,
    required this.author,
    required this.publishedDate,
    required this.color,
    required this.intro,
    required this.sections,
    required this.closingNote,
  });

  final IconData icon;
  final String category;
  final String title;
  final String readTime;
  final String author;
  final String publishedDate;
  final Color color;
  final String intro;
  final List<ArticleSection> sections;
  final String closingNote;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key, required this.article});

  final ArticleContent article;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: article.color,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleBackButton(color: article.color),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      article.color,
                      Color.lerp(article.color, Colors.black, 0.3)!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(72, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _CategoryChip(
                          label: article.category,
                          color: article.color,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          article.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: Color(0xD9FFFFFF),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              article.readTime,
                              style: const TextStyle(
                                color: Color(0xD9FFFFFF),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Icon(
                              Icons.person_rounded,
                              color: Color(0xD9FFFFFF),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                article.author,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xD9FFFFFF),
                                  fontSize: 12,
                                ),
                              ),
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

          // ── Body ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Published date
                  Text(
                    article.publishedDate,
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Intro paragraph
                  Text(
                    article.intro,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sections
                  for (final section in article.sections) ...[
                    _SectionHeading(
                      text: section.heading,
                      color: article.color,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      section.body,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 14.5,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Closing note
                  _DisclaimerBox(text: article.closingNote, color: article.color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .22),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.of(context).text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DisclaimerBox extends StatelessWidget {
  const _DisclaimerBox({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: c.muted,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
