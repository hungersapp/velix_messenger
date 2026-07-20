import 'package:flutter/material.dart';

class TimeCapsuleSection extends StatelessWidget {
  const TimeCapsuleSection({
    super.key,
    this.onYourTcTap,
    this.onUserTap,
  });

  final VoidCallback? onYourTcTap;
  final ValueChanged<String>? onUserTap;

  @override
  Widget build(BuildContext context) {
    const users = [
      'Arun',
      'Priya',
      'Kavin',
      'Meena',
      'Naveen',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            'Time Capsule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _YourTimeCapsule(
                onTap: onYourTcTap,
              ),

              const SizedBox(width: 14),

              ...users.map(
                (name) => Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _TimeCapsuleAvatar(
                    name: name,
                    onTap: () => onUserTap?.call(name),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _YourTimeCapsule extends StatelessWidget {
  const _YourTimeCapsule({
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFF2F4F7),
                    child: Icon(
                      Icons.person,
                      color: Colors.grey,
                    ),
                  ),
                ),

                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Your TC',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeCapsuleAvatar extends StatelessWidget {
  const _TimeCapsuleAvatar({
    required this.name,
    this.onTap,
  });

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2563EB),
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFF2F4F7),
                child: Icon(
                  Icons.person,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}