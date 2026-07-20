import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.photoUrl,
  });

  final String photoUrl;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 72,

      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [

            /// Menu
            IconButton(
              onPressed: () {
                // TODO : Drawer
              },
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.black87,
                size: 28,
              ),
            ),

            const SizedBox(width: 4),

            /// Logo
            Image.asset(
              'assets/images/app_logo.png',
              height: 36,
            ),

            const SizedBox(width: 10),

            /// App Name
            const Expanded(
              child: Text(
                "Velix",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ),

            /// Search Button
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: () {
                  // TODO : Search
                },
                icon: const Icon(
                  Icons.search_rounded,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(width: 10),

            /// Notification Button
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: () {
                  // TODO : Notifications
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(width: 10),

            /// Profile Photo
            GestureDetector(
              onTap: () {
                // TODO : Profile
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.black54,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}