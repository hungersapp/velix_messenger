import 'package:flutter/material.dart';

class InviteTile extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String? photoUrl;
  final VoidCallback onInvite;

  const InviteTile({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.photoUrl,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onInvite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  (photoUrl != null && photoUrl!.isNotEmpty)
                      ? NetworkImage(photoUrl!)
                      : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? Text(
                      name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phoneNumber,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            OutlinedButton(
              onPressed: onInvite,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 36),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
              child: const Text('Invite'),
            ),
          ],
        ),
      ),
    );
  }
}