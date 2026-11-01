import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'in_app_notifications.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) => const CommunityJoinPage();
}

class CommunityJoinPage extends StatefulWidget {
  const CommunityJoinPage({super.key});

  @override
  State<CommunityJoinPage> createState() => _CommunityJoinPageState();
}

class _CommunityJoinPageState extends State<CommunityJoinPage> {
  final supabase = Supabase.instance.client;
  final name = TextEditingController();
  bool loading = true;
  bool joining = false;
  bool joined = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  Future<void> _checkExistingProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final profile = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();
      final displayName = profile?['display_name']?.toString().trim() ?? '';
      if (!mounted) return;
      if (displayName.length >= 2 && displayName != 'N.G.N. Member') {
        setState(() {
          joined = true;
          loading = false;
        });
        return;
      }
    } catch (_) {
      if (mounted) error = 'Could not load your Community profile. Please try again.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _join() async {
    final displayName = name.text.trim();
    if (displayName.length < 2 || displayName.length > 40) {
      setState(() => error = 'Enter a name between 2 and 40 characters.');
      return;
    }
    setState(() {
      joining = true;
      error = null;
    });
    try {
      var user = supabase.auth.currentUser;
      if (user == null) {
        final result = await supabase.auth.signInAnonymously();
        user = result.user;
      }
      if (user == null) {
        throw const AuthException('A guest session could not be created.');
      }
      await supabase.from('profiles').upsert({
        'id': user.id,
        'display_name': displayName,
      });
      if (!mounted) return;
      setState(() => joined = true);
    } on AuthException catch (joinError) {
      if (mounted) {
        setState(() => error =
            'Guest access is not enabled yet. Please contact the N.G.N. administrator. ${joinError.message}');
      }
    } on PostgrestException catch (dbError) {
      if (mounted) setState(() => error = dbError.message);
    } catch (joinError) {
      if (mounted) setState(() => error = 'Could not join the Community: ${joinError.toString()}');
    } finally {
      if (mounted) setState(() => joining = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (joined) return const CommunityChatPage();
    return Scaffold(
        appBar: AppBar(title: const Text('N.G.N. Community')),
        body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFFE8F0FE),
                      child: Icon(Icons.groups_rounded,
                          size: 42, color: Color(0xFF0B5ED7)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome to the Community',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Enter the name you want other members to see. No email, password or registration is required.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: name,
                      maxLength: 40,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Your Community name',
                        hintText: 'Enter your name',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => joining ? null : _join(),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: joining ? null : _join,
                      child: Text(joining ? 'Joining...' : 'Enter Community'),
                    ),
                  ],
                ),
        ),
      );
  }
}

class CommunityChatPage extends StatefulWidget{const CommunityChatPage({super.key});@override State<CommunityChatPage> createState()=>_CommunityChatPageState();}
class _CommunityChatPageState extends State<CommunityChatPage>{
  final supabase=Supabase.instance.client,message=TextEditingController(),recorder=AudioRecorder(),player=AudioPlayer(),chatScroll=ScrollController();
  bool recording=false,sending=false;int recordSeconds=0;Timer? timer;String? playingId;Map<String,dynamic>? replyingTo;String? myName;String communityMode='open';
  @override void initState(){super.initState();InAppNotificationService.instance.markCommunityRead();_loadMyName();_loadCommunityMode();}
  Future<void> _loadCommunityMode()async{final r=await supabase.from('app_settings').select('value').eq('id','community_chat').maybeSingle();final value=r?['value'];final mode=value?['mode']?.toString();if(mounted)setState(()=>communityMode=mode??'open');}
  Future<void> _loadMyName()async{final user=supabase.auth.currentUser;if(user==null)return;final r=await supabase.from('profiles').select('display_name').eq('id',user.id).maybeSingle();if(!mounted)return;setState(()=>myName=r?['display_name']?.toString());if((myName??'').trim().isEmpty)WidgetsBinding.instance.addPostFrameCallback((_)=>_editMyName(required:true));}
  Future<void> _editMyName({bool required=false})async{final user=supabase.auth.currentUser;if(user==null)return;final c=TextEditingController(text:myName??'');final value=await showDialog<String>(context:context,barrierDismissible:!required,builder:(context)=>PopScope(canPop:!required,child:AlertDialog(title:const Text('Your Community name'),content:TextField(controller:c,autofocus:true,maxLength:40,decoration:const InputDecoration(hintText:'Enter the name people will see',border:OutlineInputBorder())),actions:[if(!required)TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,c.text.trim()),child:const Text('Save name'))])));c.dispose();if(value==null||value.trim().length<2){if(required&&mounted)_editMyName(required:true);return;}await supabase.from('profiles').update({'display_name':value.trim()}).eq('id',user.id);if(mounted)setState(()=>myName=value.trim());}
  Stream<List<Map<String,dynamic>>> get messages=>supabase.from('community_messages').stream(primaryKey:['id']).order('created_at', ascending: true).limit(100).map((rows)=>rows.map((r)=>Map<String,dynamic>.from(r)).toList());
  void scrollToLatest(){WidgetsBinding.instance.addPostFrameCallback((_){if(chatScroll.hasClients)chatScroll.animateTo(chatScroll.position.maxScrollExtent,duration:const Duration(milliseconds:280),curve:Curves.easeOut);});}
  Map<String,dynamic>? replyTarget(List<Map<String,dynamic>> rows,dynamic replyToId){if(replyToId==null)return null;for(final row in rows){if(row['id']==replyToId)return row;}return null;}
  Future<String> displayName(String id)async{final r=await supabase.from('profiles').select('display_name').eq('id',id).maybeSingle();return r?['display_name']?.toString()??'N.G.N. Member';}
  Future<void> sendText()async{if(communityMode=='locked')return;final text=message.text.trim(),user=supabase.auth.currentUser;if(text.isEmpty||user==null||sending)return;setState(()=>sending=true);try{await supabase.from('community_messages').insert({'author_id':user.id,'message_type':'text','body':text,'reply_to_id':replyingTo?['id']});message.clear();if(mounted)setState(()=>replyingTo=null);}on PostgrestException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}finally{if(mounted)setState(()=>sending=false);}}
  Future<void> toggleRecording()async{if(communityMode=='locked')return;if(recording){await finishRecording();return;}if(!await recorder.hasPermission()){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Microphone permission is needed for voice notes.')));return;}final dir=await getTemporaryDirectory(),path='${dir.path}/ngn_${DateTime.now().millisecondsSinceEpoch}.m4a';await recorder.start(const RecordConfig(encoder:AudioEncoder.aacLc,bitRate:48000,sampleRate:24000,numChannels:1,noiseSuppress:true),path:path);setState((){recording=true;recordSeconds=0;});timer=Timer.periodic(const Duration(seconds:1),(t){if(!mounted)return;setState(()=>recordSeconds++);if(recordSeconds>=120)finishRecording();});}
  Future<void> finishRecording()async{timer?.cancel();final seconds=recordSeconds.clamp(1,120),path=await recorder.stop();if(mounted)setState(()=>recording=false);if(path==null)return;final user=supabase.auth.currentUser;if(user==null)return;setState(()=>sending=true);final storagePath='${user.id}/${DateTime.now().millisecondsSinceEpoch}.m4a';try{await supabase.storage.from('community-voice').upload(storagePath,File(path),fileOptions:const FileOptions(contentType:'audio/mp4'));try{await supabase.from('community_messages').insert({'author_id':user.id,'message_type':'voice','voice_path':storagePath,'voice_duration_seconds':seconds,'reply_to_id':replyingTo?['id']});if(mounted)setState(()=>replyingTo=null);}catch(_){await supabase.storage.from('community-voice').remove([storagePath]);rethrow;}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Voice note could not be sent: $e')));}finally{try{await File(path).delete();}catch(_){}if(mounted)setState(()=>sending=false);}}
  Future<void> playVoice(Map<String,dynamic> row)async{final path=row['voice_path']?.toString();if(path==null)return;if(playingId==row['id']){await player.stop();if(mounted)setState(()=>playingId=null);return;}final url=await supabase.storage.from('community-voice').createSignedUrl(path,3600);await player.play(UrlSource(url));if(mounted)setState(()=>playingId=row['id']?.toString());}
  Future<void> deleteOwn(Map<String,dynamic> row)async{final voicePath=row['voice_path']?.toString(),filePath=row['file_path']?.toString();await supabase.from('community_messages').delete().eq('id',row['id']);if(voicePath!=null)await supabase.storage.from('community-voice').remove([voicePath]);if(filePath!=null)await supabase.storage.from('ngn-media').remove([filePath]);}
  String? communityFileUrl(Map<String,dynamic> row){final path=row['file_path']?.toString();if(path==null||path.isEmpty)return null;return supabase.storage.from('ngn-media').getPublicUrl(path);}
  Future<void> downloadCommunityFile(Map<String,dynamic> row)async{final url=communityFileUrl(row);if(url==null)return;final uri=Uri.tryParse(url);if(uri!=null){final ok=await launchUrl(uri,mode:LaunchMode.externalApplication);if(!ok&&mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not open this file for download.')));}}
  void previewCommunityImage(String url,String name){showDialog(context:context,builder:(dialogContext)=>Dialog(backgroundColor:Colors.black,insetPadding:const EdgeInsets.all(12),child:Stack(children:[InteractiveViewer(child:Image.network(url,fit:BoxFit.contain,width:double.infinity,errorBuilder:(_,__,___)=>const Center(child:Padding(padding:EdgeInsets.all(30),child:Text('Image could not be loaded.',style:TextStyle(color:Colors.white))))),),Positioned(top:8,right:8,child:IconButton.filled(onPressed:()=>Navigator.pop(dialogContext),icon:const Icon(Icons.close_rounded))),Positioned(left:8,right:8,bottom:8,child:SafeArea(top:false,child:FilledButton.icon(onPressed:()=>downloadCommunityFile({'file_path':url.split('/').skip(8).join('/')}),icon:const Icon(Icons.download_rounded),label:const Text('Download image'))))])));}
  Widget fileAttachment(Map<String,dynamic> row,bool mine){final name=row['file_name']?.toString()??'Community file';final mime=row['file_mime_type']?.toString().toLowerCase()??'';final isImage=mime.startsWith('image/');final url=communityFileUrl(row);final size=(row['file_size_bytes'] as num?)?.toInt();final sizeLabel=size==null?'Tap to download':'${(size/1024/1024).toStringAsFixed(1)} MB • Tap to download';if(isImage&&url!=null){return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[GestureDetector(onTap:()=>previewCommunityImage(url,name),child:ClipRRect(borderRadius:BorderRadius.circular(11),child:Image.network(url,width:260,height:190,fit:BoxFit.cover,loadingBuilder:(context,child,progress)=>progress==null?child:Container(width:260,height:150,alignment:Alignment.center,color:Colors.black12,child:const CircularProgressIndicator()),errorBuilder:(_,__,___)=>Container(width:260,height:120,color:Colors.black12,alignment:Alignment.center,child:const Icon(Icons.broken_image_outlined,size:38))))),const SizedBox(height:5),Row(children:[Expanded(child:Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:11,color:mine?Colors.white70:null))),IconButton(onPressed:()=>downloadCommunityFile(row),tooltip:'Download image',visualDensity:VisualDensity.compact,icon:Icon(Icons.download_rounded,color:mine?Colors.white:const Color(0xFF0B5ED7)))])]);}return InkWell(onTap:()=>downloadCommunityFile(row),child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:(mine?Colors.white:const Color(0xFF0B5ED7)).withValues(alpha:.12),borderRadius:BorderRadius.circular(10)),child:Row(children:[Icon(Icons.insert_drive_file_rounded,color:mine?Colors.white:const Color(0xFF0B5ED7),size:28),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,color:mine?Colors.white:null)),const SizedBox(height:3),Text(sizeLabel,style:TextStyle(fontSize:11,color:mine?Colors.white70:null))])),Icon(Icons.download_rounded,color:mine?Colors.white:const Color(0xFF0B5ED7))])));}
  Future<void> report(Map<String,dynamic> row)async{final user=supabase.auth.currentUser;if(user==null)return;await supabase.from('community_reports').insert({'reporter_id':user.id,'message_id':row['id'],'reason':'Reported from community chat'});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Message reported to N.G.N. administrators.')));}
  @override void dispose(){timer?.cancel();message.dispose();recorder.dispose();player.dispose();super.dispose();}
  @override Widget build(BuildContext context){final me=supabase.auth.currentUser?.id;return Scaffold(appBar:AppBar(title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('N.G.N. Community'),if(myName!=null)Text(myName!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.normal))]),actions:[IconButton(onPressed:()=>_editMyName(),tooltip:'Change my Community name',icon:const Icon(Icons.badge_outlined))]),body:Column(children:[
    Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:16,vertical:9),color:const Color(0xFFD4AF37).withValues(alpha:.12),child:Text(communityMode=='locked'?'Community chat is currently closed. You can read previous messages and check back for the next N.G.N. session.':communityMode=='meeting'?'N.G.N. Community meeting is now open • Fellowship with kindness':'Fellowship with kindness • Messages are automatically removed after 30 days',textAlign:TextAlign.center,style:const TextStyle(fontSize:12))),
    Expanded(child:StreamBuilder<List<Map<String,dynamic>>>(stream:messages,builder:(context,snapshot){if(snapshot.hasData){InAppNotificationService.instance.markCommunityRead();}if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());final rows=snapshot.data!;if(rows.isEmpty)return const Center(child:Text('Start the conversation. 👋'));scrollToLatest();return ListView.builder(controller:chatScroll,padding:const EdgeInsets.all(14),itemCount:rows.length,itemBuilder:(context,index){final row=rows[index],mine=row['author_id']==me;return FutureBuilder<String>(future:displayName(row['author_id'].toString()),builder:(context,n)=>Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:GestureDetector(onLongPress:()=>showModalBottomSheet(context:context,builder:(_)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[ListTile(leading:const Icon(Icons.reply_rounded),title:const Text('Reply'),onTap:(){Navigator.pop(context);setState(()=>replyingTo=row);}),if(mine)ListTile(leading:const Icon(Icons.delete_outline),title:const Text('Delete my message'),onTap:(){Navigator.pop(context);deleteOwn(row);}),if(!mine)ListTile(leading:const Icon(Icons.flag_outlined),title:const Text('Report to admin'),onTap:(){Navigator.pop(context);report(row);})]))),child:Container(constraints:const BoxConstraints(maxWidth:310),margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:mine?const Color(0xFF0B5ED7):Theme.of(context).cardColor,borderRadius:BorderRadius.circular(16),border:mine?null:Border.all(color:Theme.of(context).dividerColor)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(row['reply_to_id']!=null)Builder(builder:(context){final target=replyTarget(rows,row['reply_to_id']);final preview=target==null?'Original message unavailable':target['message_type']=='voice'?'Voice note':target['message_type']=='file'?'File: ${target['file_name']??'Attachment'}':(target['body']?.toString()??'Message');return Container(width:double.infinity,margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:9,vertical:7),decoration:BoxDecoration(color:(mine?Colors.white:const Color(0xFF0B5ED7)).withValues(alpha:.12),borderRadius:BorderRadius.circular(9),border:Border(left:BorderSide(color:mine?const Color(0xFFD4AF37):const Color(0xFF0B5ED7),width:3))),child:Row(children:[const Icon(Icons.reply_rounded,size:14),const SizedBox(width:6),Expanded(child:Text(preview,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,fontStyle:FontStyle.italic)))]));}),Text(n.data??'N.G.N. Member',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:mine?const Color(0xFFD4AF37):const Color(0xFF0B5ED7))),const SizedBox(height:5),if(row['message_type']=='voice')InkWell(onTap:()=>playVoice(row),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(playingId==row['id']?Icons.stop_circle_outlined:Icons.play_circle_outline,color:mine?Colors.white:const Color(0xFF0B5ED7)),const SizedBox(width:8),Text('Voice note • ${row['voice_duration_seconds']??0}s',style:TextStyle(color:mine?Colors.white:null))]))else if(row['message_type']=='file')fileAttachment(row,mine)else Text(row['body']?.toString()??'',style:TextStyle(color:mine?Colors.white:null,height:1.35))])))));});})),
    SafeArea(top:false,child:Column(mainAxisSize:MainAxisSize.min,children:[if(replyingTo!=null)Container(margin:const EdgeInsets.fromLTRB(10,6,10,0),padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(12)),child:Row(children:[const Icon(Icons.reply_rounded,size:18),const SizedBox(width:8),Expanded(child:Text(replyingTo!['message_type']=='voice'?'Replying to voice note':replyingTo!['message_type']=='file'?'Replying to file: ${replyingTo!['file_name']??'Attachment'}':(replyingTo!['body']?.toString()??'Replying to message'),maxLines:1,overflow:TextOverflow.ellipsis)),IconButton(onPressed:()=>setState(()=>replyingTo=null),icon:const Icon(Icons.close_rounded),visualDensity:VisualDensity.compact)])),Padding(padding:const EdgeInsets.fromLTRB(10,8,10,10),child:Row(children:[IconButton.filledTonal(onPressed:sending||communityMode=='locked'?null:toggleRecording,icon:Icon(recording?Icons.stop_rounded:Icons.mic_none_rounded),tooltip:recording?'Stop voice note':'Record voice note'),const SizedBox(width:8),Expanded(child:TextField(controller:message,enabled:!recording&&communityMode!='locked',maxLength:2000,minLines:1,maxLines:4,decoration:InputDecoration(counterText:'',hintText:communityMode=='locked'?'Community chat is closed':recording?'Recording… $recordSeconds/120s':'Message the community',border:OutlineInputBorder(borderRadius:BorderRadius.circular(22))))),const SizedBox(width:8),IconButton.filled(onPressed:sending||recording||communityMode=='locked'?null:sendText,icon:sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded))]))]))
  ]));}
}
