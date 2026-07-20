import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    this.photoUrl = '',
    this.onSearch,
    this.onProfile,
  });

  final String photoUrl;
  final VoidCallback? onSearch;
  final VoidCallback? onProfile;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 72,
      centerTitle: false,

      title: Row(
        children: [
          Image.asset(
            'assets/images/app_logo.png',
            height: 38,
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Velix',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: .4,
                color: Colors.black87,
              ),
            ),
          ),

          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: onSearch,
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(width: 10),

          GestureDetector(
            onTap: onProfile,
            child: CircleAvatar(
              radius: 21,
              backgroundColor: const Color(0xFFF4F5F8),
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: Colors.black54,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}