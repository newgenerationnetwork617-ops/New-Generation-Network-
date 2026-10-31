import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});
  @override
  Widget build(BuildContext context) => Supabase.instance.client.auth.currentUser == null ? const CommunityAuthPage() : const CommunityChatPage();
}
class CommunityAuthPage extends StatefulWidget {
  const CommunityAuthPage({super.key});
  @override State<CommunityAuthPage> createState()=>_CommunityAuthPageState();
}
class _CommunityAuthPageState extends State<CommunityAuthPage>{
  final supabase=Supabase.instance.client,name=TextEditingController(),email=TextEditingController(),password=TextEditingController();
  bool createAccount=false,loading=false; String? error;
  Future<void> submit()async{
    if(email.text.trim().isEmpty||password.text.length<6||(createAccount&&name.text.trim().length<2)){setState(()=>error='Enter a valid email, a password of at least 6 characters, and any required display name.');return;}
    setState((){loading=true;error=null;});
    try{
      if(createAccount){
        final result=await supabase.auth.signUp(email:email.text.trim(),password:password.text);final user=result.user;if(user==null)throw const AuthException('Could not create account.');
        if(result.session==null){if(mounted)setState(()=>error='Account created. Check your email to confirm it, then sign in.');return;}
        await supabase.from('profiles').upsert({'id':user.id,'display_name':name.text.trim()});
      }else{
        final result=await supabase.auth.signInWithPassword(email:email.text.trim(),password:password.text);final user=result.user!;
        final profile=await supabase.from('profiles').select('id').eq('id',user.id).maybeSingle();
        if(profile==null){var fallback=email.text.split('@').first;if(fallback.length>40)fallback=fallback.substring(0,40);if(fallback.length<2)fallback='N.G.N. Member';await supabase.from('profiles').insert({'id':user.id,'display_name':fallback});}
      }
      if(!mounted)return;Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const CommunityChatPage()));
    }on AuthException catch(e){if(mounted)setState(()=>error=e.message);}on PostgrestException catch(e){if(mounted)setState(()=>error=e.message);}finally{if(mounted)setState(()=>loading=false);}
  }
  @override void dispose(){name.dispose();email.dispose();password.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('N.G.N. Community')),body:ListView(padding:const EdgeInsets.all(20),children:[
    const Icon(Icons.groups_rounded,size:56,color:Color(0xFF0B5ED7)),const SizedBox(height:16),Text(createAccount?'Join the Community':'Community Sign In',textAlign:TextAlign.center,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),
    const SizedBox(height:8),const Text('Only Community requires an account. The rest of N.G.N. remains open to everyone.',textAlign:TextAlign.center),const SizedBox(height:24),
    if(createAccount)TextField(controller:name,maxLength:40,decoration:const InputDecoration(labelText:'Display name',border:OutlineInputBorder())),if(createAccount)const SizedBox(height:12),
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email',border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Password',border:OutlineInputBorder())),
    if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),const SizedBox(height:18),
    FilledButton(onPressed:loading?null:submit,child:Text(loading?'Please wait...':(createAccount?'Create account':'Sign in'))),
    TextButton(onPressed:loading?null:()=>setState((){createAccount=!createAccount;error=null;}),child:Text(createAccount?'Already have an account? Sign in':'New here? Create a Community account'))
  ]));
}
class CommunityChatPage extends StatefulWidget{const CommunityChatPage({super.key});@override State<CommunityChatPage> createState()=>_CommunityChatPageState();}
class _CommunityChatPageState extends State<CommunityChatPage>{
  final supabase=Supabase.instance.client,message=TextEditingController(),recorder=AudioRecorder(),player=AudioPlayer();
  bool recording=false,sending=false;int recordSeconds=0;Timer? timer;String? playingId;
  Stream<List<Map<String,dynamic>>> get messages=>supabase.from('community_messages').stream(primaryKey:['id']).order('created_at').limit(100).map((rows)=>rows.map((r)=>Map<String,dynamic>.from(r)).toList());
  Future<String> displayName(String id)async{final r=await supabase.from('profiles').select('display_name').eq('id',id).maybeSingle();return r?['display_name']?.toString()??'N.G.N. Member';}
  Future<void> sendText()async{final text=message.text.trim(),user=supabase.auth.currentUser;if(text.isEmpty||user==null||sending)return;setState(()=>sending=true);try{await supabase.from('community_messages').insert({'author_id':user.id,'message_type':'text','body':text});message.clear();}on PostgrestException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}finally{if(mounted)setState(()=>sending=false);}}
  Future<void> toggleRecording()async{if(recording){await finishRecording();return;}if(!await recorder.hasPermission()){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Microphone permission is needed for voice notes.')));return;}final dir=await getTemporaryDirectory(),path='${dir.path}/ngn_${DateTime.now().millisecondsSinceEpoch}.m4a';await recorder.start(const RecordConfig(encoder:AudioEncoder.aacLc,bitRate:48000,sampleRate:24000,numChannels:1,noiseSuppress:true),path:path);setState((){recording=true;recordSeconds=0;});timer=Timer.periodic(const Duration(seconds:1),(t){if(!mounted)return;setState(()=>recordSeconds++);if(recordSeconds>=120)finishRecording();});}
  Future<void> finishRecording()async{timer?.cancel();final seconds=recordSeconds.clamp(1,120),path=await recorder.stop();if(mounted)setState(()=>recording=false);if(path==null)return;final user=supabase.auth.currentUser;if(user==null)return;setState(()=>sending=true);final storagePath='${user.id}/${DateTime.now().millisecondsSinceEpoch}.m4a';try{await supabase.storage.from('community-voice').upload(storagePath,File(path),fileOptions:const FileOptions(contentType:'audio/mp4'));try{await supabase.from('community_messages').insert({'author_id':user.id,'message_type':'voice','voice_path':storagePath,'voice_duration_seconds':seconds});}catch(_){await supabase.storage.from('community-voice').remove([storagePath]);rethrow;}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Voice note could not be sent: $e')));}finally{try{await File(path).delete();}catch(_){}if(mounted)setState(()=>sending=false);}}
  Future<void> playVoice(Map<String,dynamic> row)async{final path=row['voice_path']?.toString();if(path==null)return;if(playingId==row['id']){await player.stop();if(mounted)setState(()=>playingId=null);return;}final url=await supabase.storage.from('community-voice').createSignedUrl(path,3600);await player.play(UrlSource(url));if(mounted)setState(()=>playingId=row['id']?.toString());}
  Future<void> deleteOwn(Map<String,dynamic> row)async{final path=row['voice_path']?.toString();await supabase.from('community_messages').delete().eq('id',row['id']);if(path!=null)await supabase.storage.from('community-voice').remove([path]);}
  Future<void> report(Map<String,dynamic> row)async{final user=supabase.auth.currentUser;if(user==null)return;await supabase.from('community_reports').insert({'reporter_id':user.id,'message_id':row['id'],'reason':'Reported from community chat'});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Message reported to N.G.N. administrators.')));}
  Future<void> signOut()async{await supabase.auth.signOut();if(!mounted)return;Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const CommunityAuthPage()));}
  @override void dispose(){timer?.cancel();message.dispose();recorder.dispose();player.dispose();super.dispose();}
  @override Widget build(BuildContext context){final me=supabase.auth.currentUser?.id;return Scaffold(appBar:AppBar(title:const Text('N.G.N. Community'),actions:[IconButton(onPressed:signOut,tooltip:'Community sign out',icon:const Icon(Icons.logout_rounded))]),body:Column(children:[
    Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:16,vertical:9),color:const Color(0xFFD4AF37).withValues(alpha:.12),child:const Text('Fellowship with kindness • Messages are automatically removed after 30 days',textAlign:TextAlign.center,style:TextStyle(fontSize:12))),
    Expanded(child:StreamBuilder<List<Map<String,dynamic>>>(stream:messages,builder:(context,snapshot){if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());final rows=snapshot.data!;if(rows.isEmpty)return const Center(child:Text('Start the conversation. 👋'));return ListView.builder(reverse:true,padding:const EdgeInsets.all(14),itemCount:rows.length,itemBuilder:(context,index){final row=rows[rows.length-1-index],mine=row['author_id']==me;return FutureBuilder<String>(future:displayName(row['author_id'].toString()),builder:(context,n)=>Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:GestureDetector(onLongPress:()=>showModalBottomSheet(context:context,builder:(_)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[if(mine)ListTile(leading:const Icon(Icons.delete_outline),title:const Text('Delete my message'),onTap:(){Navigator.pop(context);deleteOwn(row);}),if(!mine)ListTile(leading:const Icon(Icons.flag_outlined),title:const Text('Report to admin'),onTap:(){Navigator.pop(context);report(row);})]))),child:Container(constraints:const BoxConstraints(maxWidth:310),margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:mine?const Color(0xFF0B5ED7):Theme.of(context).cardColor,borderRadius:BorderRadius.circular(16),border:mine?null:Border.all(color:Theme.of(context).dividerColor)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(n.data??'N.G.N. Member',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:mine?const Color(0xFFD4AF37):const Color(0xFF0B5ED7))),const SizedBox(height:5),if(row['message_type']=='voice')InkWell(onTap:()=>playVoice(row),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(playingId==row['id']?Icons.stop_circle_outlined:Icons.play_circle_outline,color:mine?Colors.white:const Color(0xFF0B5ED7)),const SizedBox(width:8),Text('Voice note • ${row['voice_duration_seconds']??0}s',style:TextStyle(color:mine?Colors.white:null))]))else Text(row['body']?.toString()??'',style:TextStyle(color:mine?Colors.white:null,height:1.35))]))))));});})),
    SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(10,8,10,10),child:Row(children:[IconButton.filledTonal(onPressed:sending?null:toggleRecording,icon:Icon(recording?Icons.stop_rounded:Icons.mic_none_rounded),tooltip:recording?'Stop voice note':'Record voice note'),const SizedBox(width:8),Expanded(child:TextField(controller:message,enabled:!recording,maxLength:2000,minLines:1,maxLines:4,decoration:InputDecoration(counterText:'',hintText:recording?'Recording… $recordSeconds/120s':'Message the community',border:OutlineInputBorder(borderRadius:BorderRadius.circular(22))))),const SizedBox(width:8),IconButton.filled(onPressed:sending||recording?null:sendText,icon:sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded))])))
  ]));}
}
