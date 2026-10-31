import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCommunityPage extends StatefulWidget {
  const AdminCommunityPage({super.key});
  @override State<AdminCommunityPage> createState()=>_AdminCommunityPageState();
}
class _AdminCommunityPageState extends State<AdminCommunityPage>{
  final supabase=Supabase.instance.client;
  bool loading=true; String communityMode='open'; List<Map<String,dynamic>> profiles=[],messages=[],reports=[];
  Future<void> load()async{
    setState(()=>loading=true);
    final setting=await supabase.from('app_settings').select('value').eq('id','community_chat').maybeSingle();
    final results=await Future.wait([
      supabase.from('profiles').select('id,display_name,is_muted,is_banned,created_at').order('created_at',ascending:false).limit(200),
      supabase.from('community_messages').select('id,author_id,message_type,body,voice_path,created_at').order('created_at',ascending:false).limit(200),
      supabase.from('community_reports').select('id,reporter_id,message_id,reason,created_at').order('created_at',ascending:false).limit(200),
    ]);
    final settingValue=setting?['value'];
    final mode=settingValue is Map<String,dynamic>?settingValue['mode']?.toString():null;
    if(!mounted)return;setState((){communityMode=mode??'open';profiles=List<Map<String,dynamic>>.from(results[0]);messages=List<Map<String,dynamic>>.from(results[1]);reports=List<Map<String,dynamic>>.from(results[2]);loading=false;});
  }
  @override void initState(){super.initState();load();}
  String nameFor(String? id){for(final p in profiles){if(p['id']==id)return p['display_name']?.toString()??'Member';}return'Member';}
  Future<void> status(Map<String,dynamic> p,{bool? muted,bool? banned})async{await supabase.from('profiles').update({'is_muted':muted??p['is_muted'],'is_banned':banned??p['is_banned']}).eq('id',p['id']);await load();}
  Future<void> setCommunityMode(String mode)async{await supabase.from('app_settings').upsert({'id':'community_chat','value':{'mode':mode},'updated_at':DateTime.now().toUtc().toIso8601String()});if(mounted)setState(()=>communityMode=mode);}
  Future<void> deleteMessage(Map<String,dynamic> m)async{final path=m['voice_path']?.toString();await supabase.from('community_messages').delete().eq('id',m['id']);if(path!=null)await supabase.storage.from('community-voice').remove([path]);await load();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Community Moderation'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh_rounded))]),body:loading?const Center(child:CircularProgressIndicator()):DefaultTabController(length:3,child:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(12,10,12,6),child:Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Community access',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),SegmentedButton<String>(segments:const [ButtonSegment(value:'open',label:Text('Open'),icon:Icon(Icons.forum_outlined)),ButtonSegment(value:'meeting',label:Text('Meeting'),icon:Icon(Icons.groups_outlined)),ButtonSegment(value:'locked',label:Text('Locked'),icon:Icon(Icons.lock_outline))],selected:{communityMode},onSelectionChanged:(v)=>setCommunityMode(v.first)),const SizedBox(height:6),Text(communityMode=='locked'?'Members can read, but only admins can post.':communityMode=='meeting'?'Meeting mode is active for the current N.G.N. session.':'Community is open for normal fellowship.',style:const TextStyle(fontSize:12))]))),
    const TabBar(tabs:[Tab(text:'Members'),Tab(text:'Messages'),Tab(text:'Reports')]),
    Expanded(child:TabBarView(children:[
      ListView.builder(itemCount:profiles.length,itemBuilder:(context,i){final p=profiles[i],muted=p['is_muted']==true,banned=p['is_banned']==true;return ListTile(leading:CircleAvatar(child:Text((p['display_name']?.toString()??'M').substring(0,1).toUpperCase())),title:Text(p['display_name']?.toString()??'Member'),subtitle:Text(banned?'BANNED':muted?'Muted':'Active'),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='mute')status(p,muted:!muted);if(v=='ban')status(p,banned:!banned);},itemBuilder:(_)=>[PopupMenuItem(value:'mute',child:Text(muted?'Unmute':'Mute')),PopupMenuItem(value:'ban',child:Text(banned?'Unban':'Ban'))]));}),
      ListView.builder(itemCount:messages.length,itemBuilder:(context,i){final m=messages[i];return ListTile(leading:Icon(m['message_type']=='voice'?Icons.mic_rounded:Icons.chat_bubble_outline),title:Text(nameFor(m['author_id']?.toString())),subtitle:Text(m['message_type']=='voice'?'Voice note':m['body']?.toString()??''),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>deleteMessage(m)));}),
      reports.isEmpty?const Center(child:Text('No reports.')):ListView.builder(itemCount:reports.length,itemBuilder:(context,i){final r=reports[i];return ListTile(leading:const Icon(Icons.flag_outlined),title:Text(r['reason']?.toString()??'Reported message'),subtitle:Text('Reporter: ${nameFor(r['reporter_id']?.toString())}\nMessage ID: ${r['message_id']}'));})
    ]))
  ])));
}
