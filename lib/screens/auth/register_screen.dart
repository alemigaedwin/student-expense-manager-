import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController(); final email = TextEditingController(); final password = TextEditingController(); final confirm = TextEditingController();
  @override void dispose(){name.dispose();email.dispose();password.dispose();confirm.dispose();super.dispose();}
  Future<void> _register() async {
    if(password.text != confirm.text){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match.')));return;}
    final success = await context.read<AppState>().registerUser(name.text,email.text,password.text);
    if(!mounted) return;
    if(success){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please log in.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AppState>().syncError ?? 'Registration failed. Check the server connection and try again.')));
    }
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar: AppBar(title: Text('Create account')),body: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.all(28),child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 430),child: Column(children:[SizedBox(height:20),Text('Create your student account',style: TextStyle(fontSize:24,fontWeight:FontWeight.w800)),SizedBox(height:24),TextField(controller:name,decoration:InputDecoration(labelText:'Full name',prefixIcon:Icon(Icons.person_outline))),SizedBox(height:14),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:InputDecoration(labelText:'Email',prefixIcon:Icon(Icons.email_outlined))),SizedBox(height:14),TextField(controller:password,obscureText:true,decoration:InputDecoration(labelText:'Password',prefixIcon:Icon(Icons.lock_outline))),SizedBox(height:14),TextField(controller:confirm,obscureText:true,decoration:InputDecoration(labelText:'Confirm password',prefixIcon:Icon(Icons.lock_reset))),SizedBox(height:24),SizedBox(width:double.infinity,child:FilledButton(onPressed:_register,child:Padding(padding:EdgeInsets.all(13),child:Text('Create account')))),SizedBox(height:10),Text('Your account will be saved to the database. After registration, return to Login to sign in.',textAlign:TextAlign.center,style:TextStyle(color:AppColors.textSecondary,fontSize:12))])))));
}
