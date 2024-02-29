import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sn/pocketbase_auth.dart';

class PasswordResetForm extends StatefulWidget {
  const PasswordResetForm({
    super.key,
  });

  @override
  State<PasswordResetForm> createState() => _PasswordResetFormState();
}

class _PasswordResetFormState extends State<PasswordResetForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<PocketBaseAuthNotifier>(builder: (context, auth, child) {
      return Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 158, 183, 58),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await auth.passwordReset(
                      _emailController.text,
                    );
                    Navigator.popAndPushNamed(context, '/');
                  }
                },
                child: Text(auth.isLoading ? 'Loading...' : 'Send Reset Email'),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Navigator.popAndPushNamed(context, '/login');
                },
                child: Text('Login'),
              ),
              if (auth.errorOccurred)
                Text(
                  auth.errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      );
    });
  }
}
