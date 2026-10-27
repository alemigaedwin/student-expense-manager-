import 'package:flutter/material.dart';
import '../../services/backend_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState()=>_NotificationsScreenState();
}
class _NotificationsScreenState extends State<NotificationsScreen>{
  bool loading=true, saving=false; String? error; List<dynamic> notices=[]; Map<String,dynamic> summary={};
  final phone=TextEditingController(); final threshold=TextEditingController(text:'0');
  bool emailEnabled=true,smsEnabled=false,dailyEnabled=true,balanceEnabled=true, prefsLoaded=false;
  @override void initState(){super.initState();_load();}
  @override void dispose(){phone.dispose();threshold.dispose();super.dispose();}
  Future<void> _load() async {
    try {
      final r=await BackendService.notifications(); final d=Map<String,dynamic>.from(r['data'] as Map? ?? {});
      final p=Map<String,dynamic>.from(d['preferences'] as Map? ?? {});
      if(!mounted)return;
      setState(() { notices=d['notifications'] as List? ?? []; summary=Map<String,dynamic>.from(d['summary'] as Map? ?? {}); phone.text='${p['phoneNumber']??''}'; threshold.text='${p['lowBalanceThreshold']??0}'; emailEnabled=p['emailEnabled']!=false; smsEnabled=p['smsEnabled']==true; dailyEnabled=p['dailyReminderEnabled']!=false; balanceEnabled=p['balanceAlertEnabled']!=false; prefsLoaded=true; loading=false; error=null; });
      await BackendService.markNotificationsRead();
    } catch(e){if(!mounted)return;setState(() { loading=false; error=e.toString().replaceFirst('Exception: ',''); });}
  }
  Future<void> _save() async {
    setState(()=>saving=true);
    try {
      await BackendService.saveNotificationPreferences({'phoneNumber':phone.text.trim(),'emailEnabled':emailEnabled,'smsEnabled':smsEnabled,'dailyReminderEnabled':dailyEnabled,'balanceAlertEnabled':balanceEnabled,'lowBalanceThreshold':double.tryParse(threshold.text.trim())??0});
      if(!mounted)return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Notification preferences saved successfully.')));
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save preferences: $e')));}
    finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Notifications & alerts'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Could not load notifications. Check that you are logged in and the API is reachable.\n$error',textAlign:TextAlign.center))):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(14),children:[
      Card(child:ListTile(leading:const Icon(Icons.account_balance_wallet),title:const Text('Current recorded balance'),subtitle:Text('Income: ${summary['income']??0}  •  Expenses: ${summary['expense']??0}'),trailing:Text('${summary['balance']??0}',style:const TextStyle(fontWeight:FontWeight.bold)))),
      const SizedBox(height:8), const Text('Delivery settings',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      SwitchListTile(value:emailEnabled,onChanged:(v)=>setState(()=>emailEnabled=v),title:const Text('Email notifications'),subtitle:const Text('Daily check-in and balance alerts')),
      SwitchListTile(value:smsEnabled,onChanged:(v)=>setState(()=>smsEnabled=v),title:const Text('SMS notifications'),subtitle:const Text('Requires configured Twilio SMS credentials')),
      TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone number for SMS',hintText:'+2567XXXXXXXX',prefixIcon:Icon(Icons.phone))),
      SwitchListTile(value:dailyEnabled,onChanged:(v)=>setState(()=>dailyEnabled=v),title:const Text('Daily income/expense reminder')),
      SwitchListTile(value:balanceEnabled,onChanged:(v)=>setState(()=>balanceEnabled=v),title:const Text('Low balance alerts')),
      TextField(controller:threshold,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Alert when balance is at or below',helperText:'Enter amount in your app currency; 0 means zero or negative balance.')),
      const SizedBox(height:8),FilledButton.icon(onPressed:saving?null:_save,icon:const Icon(Icons.save),label:Text(saving?'Saving...':'Save notification settings')),
      const Divider(height:28),const Text('Notification history',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      if(notices.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('No notifications yet. Daily reminders appear after the scheduled notification task runs.',textAlign:TextAlign.center)) else ...notices.map((n){final m=Map<String,dynamic>.from(n as Map);return Card(child:ListTile(leading:Icon(m['type']=='balance_alert'?Icons.account_balance_wallet_outlined:Icons.notifications_active_outlined),title:Text('${m['title']??'Notification'}'),subtitle:Text('${m['message']??''}\n${m['channel']??'in_app'} • ${m['deliveryStatus']??''}'),isThreeLine:true));})
    ])));
}
