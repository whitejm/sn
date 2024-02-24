import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sn/pocketbase_auth.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
  });

  @override
  State<LoginForm> createState() => _LoginForm();
}

class _LoginForm extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your password' : null,
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      print("calling sign in");
                      await auth.signIn(
                        _emailController.text,
                        _passwordController.text,
                      );
                      Navigator.pushNamed(context, '/');
                    }
                  },
                  child: Text(auth.isLoading ? 'Loading...' : 'Login'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text('Sign Up'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/resetpassword');
                  },
                  child: Text('Reset Password'),
                ),
                if (auth.errorOccurred)
                  Text(
                    auth.errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ));
    });
  }
}
