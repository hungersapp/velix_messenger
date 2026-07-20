import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/screens/home_screen.dart';
import '../providers/first_user_provider.dart';
import '../../domain/entities/user_entity.dart';

class FirstUserEntryScreen extends ConsumerStatefulWidget {
  const FirstUserEntryScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.name,
    required this.photoUrl,
  });

  final String uid;
  final String email;
  final String name;
  final String photoUrl;

  @override
  ConsumerState<FirstUserEntryScreen> createState() =>
      _FirstUserEntryScreenState();
}

class _FirstUserEntryScreenState
    extends ConsumerState<FirstUserEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final TextEditingController _mobileController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(firstUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter your name";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter mobile number";
                    }

                    if (value.length != 10) {
                      return "Enter valid mobile number";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            final mobile =
                                _mobileController.text.trim();

                            final exists = await ref
                                .read(firstUserProvider.notifier)
                                .mobileExists(mobile);

                            if (!context.mounted) return;

                            if (exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Mobile number already exists",
                                  ),
                                ),
                              );
                              return;
                            }

                            final user = UserEntity(
                              uid: widget.uid,
                              name: _nameController.text.trim(),
                              mobile: mobile,
                              email: widget.email,
                              photoUrl: widget.photoUrl,
                              createdAt: DateTime.now(),
                            );

                            await ref
                                .read(firstUserProvider.notifier)
                                .saveUser(user);

                            if (!context.mounted) return;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            );
                          },
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Continue"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}