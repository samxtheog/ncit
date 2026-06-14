import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/community_service.dart';

// ── Tag options ───────────────────────────────────────────────────────────────
const _tags = [
  'General', 'Study Tip', 'Career Match', 'JavaScript',
  'Mathematics', 'Science', 'Motivation', 'Question',
];

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60)  return 'just now';
  if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)    return '${diff.inHours}h ago';
  if (diff.inDays < 7)      return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

// ── Tag color map ─────────────────────────────────────────────────────────────
Color _tagColor(String tag) {
  const map = {
    'Study Tip':    Color(0xFF1A6B4A),
    'Career Match': Color(0xFF9C27B0),
    'JavaScript':   Color(0xFF5483B3),
    'Mathematics':  Color(0xFFD4732A),
    'Science':      Color(0xFF00838F),
    'Motivation':   Color(0xFFE53935),
    'Question':     Color(0xFF7C4DFF),
  };
  return map[tag] ?? AppColors.primary;
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  CommunityTab                                                               ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});
  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  final _service    = CommunityService();
  final _scrollCtrl = ScrollController();

  List<CommunityPost> _posts    = [];
  bool   _loading               = true;
  bool   _loadingMore           = false;
  String? _error;
  int    _page                  = 1;
  int    _totalPages            = 1;

  String _myUserId = '';
  String _myName   = '';

  @override
  void initState() {
    super.initState();
    _init();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString(AppConstants.keyUserId)   ?? '';
    _myName   = prefs.getString(AppConstants.keyUserName) ?? 'You';
    _fetchPosts(reset: true);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _page < _totalPages) {
      _fetchMore();
    }
  }

  Future<void> _fetchPosts({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; });
    }
    try {
      final result = await _service.getPosts(page: 1);
      if (!mounted) return;
      setState(() {
        _posts      = result.posts;
        _totalPages = result.pages;
        _page       = 1;
        _loading    = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _fetchMore() async {
    setState(() => _loadingMore = true);
    try {
      final result = await _service.getPosts(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _posts.addAll(result.posts);
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  // ── Like ──────────────────────────────────────────────────────────────────

  Future<void> _like(int idx) async {
    final post = _posts[idx];
    // Optimistic update
    setState(() {
      _posts[idx] = post.copyWith(
        likedByMe: !post.likedByMe,
        likeCount: post.likedByMe ? post.likeCount - 1 : post.likeCount + 1,
      );
    });
    try {
      final res = await _service.toggleLike(post.id);
      if (!mounted) return;
      setState(() {
        _posts[idx] = _posts[idx].copyWith(
          likeCount: res.likeCount,
          likedByMe: res.likedByMe,
        );
      });
    } catch (_) {
      // Roll back
      if (mounted) setState(() { _posts[idx] = post; });
    }
  }

  // ── Create post ───────────────────────────────────────────────────────────

  void _openComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PostComposer(
        myName: _myName,
        onPost: (content, tag) async {
          Navigator.pop(ctx);
          try {
            final post = await _service.createPost(
                content: content, tag: tag);
            if (mounted) setState(() => _posts.insert(0, post));
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())));
            }
          }
        },
      ),
    );
  }

  // ── Comments sheet ────────────────────────────────────────────────────────

  void _openComments(int idx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(
        post: _posts[idx],
        myName: _myName,
        onComment: (content) async {
          try {
            final comment =
                await _service.addComment(_posts[idx].id, content);
            if (!mounted) return;
            setState(() {
              _posts[idx] = _posts[idx].copyWith(
                commentCount: _posts[idx].commentCount + 1,
                comments: [..._posts[idx].comments, comment],
              );
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())));
            }
          }
        },
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deletePost(int idx) async {
    final post = _posts[idx];
    setState(() => _posts.removeAt(idx));
    try {
      await _service.deletePost(post.id);
    } catch (_) {
      if (mounted) setState(() => _posts.insert(idx, post));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Header + composer ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppConstants.horizontalPadding,
              right: AppConstants.horizontalPadding,
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Text('Community', style: AppTextStyles.headlineLarge),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Learn together with fellow students',
                    style: AppTextStyles.bodyMedium),
                const SizedBox(height: 20),
                _ComposerBar(
                  initial: _myName.isNotEmpty ? _myName[0].toUpperCase() : 'S',
                  onTap: _openComposer,
                ),
              ],
            ),
          ),
        ),

        // ── Body ──────────────────────────────────────────────────────────
        if (_loading)
          SliverFillRemaining(child: _buildSkeleton())
        else if (_error != null && _posts.isEmpty)
          SliverFillRemaining(child: _buildError())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == _posts.length) {
                    return _loadingMore
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : const SizedBox(height: 100);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PostCard(
                      post:     _posts[i],
                      isOwner:  _posts[i].userId == _myUserId,
                      onLike:   () => _like(i),
                      onComment:() => _openComments(i),
                      onDelete: () => _deletePost(i),
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fade(duration: 350.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
                },
                childCount: _posts.length + 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkeleton() => Padding(
    padding: const EdgeInsets.all(AppConstants.horizontalPadding),
    child: Column(
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
        ),
      ).animate(delay: Duration(milliseconds: i * 80)).shimmer(
            duration: 1200.ms, color: AppColors.lightAccent)),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          Text('Could not load posts', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('Check your connection and try again.',
              style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _fetchPosts(reset: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    ),
  );
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Composer bar                                                               ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class _ComposerBar extends StatelessWidget {
  final String initial;
  final VoidCallback onTap;
  const _ComposerBar({required this.initial, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
          border: Border.all(color: const Color(0xFFDDE8F5), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Share something with the community...',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text('Post',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Post card                                                                  ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final bool isOwner;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.isOwner,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _tagColor(post.tag);
    final initials = post.name.trim().split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author row ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Center(
                  child: Text(initials,
                      style: AppTextStyles.titleSmall.copyWith(
                          color: color, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.name,
                        style: AppTextStyles.titleMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(_timeAgo(post.createdAt),
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              // Tag pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(post.tag,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: color, fontWeight: FontWeight.w600)),
              ),
              if (isOwner) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFE53935), size: 18),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),
          Text(post.content,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEEF4FB), height: 1),
          const SizedBox(height: 10),

          // ── Actions ────────────────────────────────────────────────────
          Row(
            children: [
              _ActionBtn(
                icon: post.likedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: post.likeCount.toString(),
                color: const Color(0xFFE53935),
                active: post.likedByMe,
                onTap: onLike,
              ),
              const SizedBox(width: 20),
              _ActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: post.commentCount.toString(),
                color: AppColors.primary,
                onTap: onComment,
              ),
              const Spacer(),
              // Preview first comment if any
              if (post.comments.isNotEmpty)
                Flexible(
                  child: Text(
                    '💬 ${post.comments.last.name}: ${post.comments.last.content}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon,
            color: active ? color : AppColors.textMuted, size: 18),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.labelMedium.copyWith(
                color: active ? color : AppColors.textMuted,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Post composer bottom sheet                                                 ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class _PostComposer extends StatefulWidget {
  final String myName;
  final void Function(String content, String tag) onPost;
  const _PostComposer({required this.myName, required this.onPost});

  @override
  State<_PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<_PostComposer> {
  final _ctrl    = TextEditingController();
  String _tag    = 'General';
  bool _posting  = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _submit() {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    setState(() => _posting = true);
    widget.onPost(txt, _tag);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDE8F5),
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
            const SizedBox(height: 18),
            Text('New Post', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),

            // Text field
            TextField(
              controller: _ctrl,
              maxLines: 4,
              maxLength: 1000,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 12),

            // Tag selector
            Text('Tag', style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((t) {
                final sel = t == _tag;
                final c = _tagColor(t);
                return GestureDetector(
                  onTap: () => setState(() => _tag = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? c : c.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? c : c.withOpacity(0.25)),
                    ),
                    child: Text(t,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: sel ? Colors.white : c,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _posting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _posting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Post',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Comments bottom sheet                                                      ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class _CommentsSheet extends StatefulWidget {
  final CommunityPost post;
  final String myName;
  final Future<void> Function(String) onComment;
  const _CommentsSheet({
    required this.post,
    required this.myName,
    required this.onComment,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl      = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool  _sending   = false;
  List<CommunityComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.post.comments);
  }

  @override
  void dispose() { _ctrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await widget.onComment(txt);
      // Re-fetch comments from the parent state after post
      if (mounted) setState(() => _sending = false);
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDE8F5),
                      borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Comments',
                      style: AppTextStyles.headlineSmall),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${widget.post.commentCount}',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFEEF4FB), height: 1),

            // Comments list
            Flexible(
              child: _comments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              color: AppColors.textMuted, size: 40),
                          const SizedBox(height: 10),
                          Text('No comments yet. Be the first!',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => const Divider(
                          color: Color(0xFFEEF4FB), height: 20),
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        final initials = c.name.trim().split(' ')
                            .map((w) => w.isNotEmpty ? w[0] : '')
                            .take(2).join().toUpperCase();
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text(initials,
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(c.name,
                                          style: AppTextStyles.titleSmall
                                              .copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 6),
                                      Text(_timeAgo(c.createdAt),
                                          style: AppTextStyles.labelSmall
                                              .copyWith(color: AppColors.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(c.content,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(height: 1.5)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // Input
            const Divider(color: Color(0xFFEEF4FB), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: Color(0xFFDDE8F5))),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _sending
                            ? AppColors.primary.withOpacity(0.5)
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Center(
                              child: SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
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
