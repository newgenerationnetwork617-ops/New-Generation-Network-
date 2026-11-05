import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'community_archive_service.dart';
import 'community_stories_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = true;
  bool busy = false;
  bool joined = false;
  bool isSignUp = false;
  bool isResetRequest = false;
  bool isPasswordRecovery = false;
  bool obscurePassword = true;
  String? error;
  String? notice;
  StreamSubscription<AuthState>? _authSubscription;

  static const callbackUrl = 'ngncommunity://login-callback/';

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          setState(() {
            isPasswordRecovery = true;
            isResetRequest = false;
            isSignUp = false;
            loading = false;
            error = null;
            notice = 'Choose a new password for your account.';
          });
        }
        return;
      }
      final user = state.session?.user;
      if (state.event == AuthChangeEvent.signedIn &&
          user != null &&
          !user.isAnonymous) {
        _saveProfile(user);
      }
    });
    _checkExistingProfile();
  }

  Future<void> _checkExistingProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) setState(() => loading = false);
      return;
    }
    await _saveProfile(user);
  }

  Future<void> _saveProfile(User user) async {
    try {
      final metadata = user.userMetadata ?? const <String, dynamic>{};
      final profile = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();
      final existingName = profile?['display_name']?.toString().trim() ?? '';
      final accountName = (metadata['full_name'] ??
              metadata['name'] ??
              user.email?.split('@').first ??
              'N.G.N. Member')
          .toString()
          .trim();
      final displayName = existingName.length >= 2 &&
              existingName != 'N.G.N. Member'
          ? existingName
          : accountName;
      final avatar =
          (metadata['avatar_url'] ?? metadata['picture'] ?? '').toString().trim();
      await supabase.from('profiles').upsert({
        'id': user.id,
        'display_name': displayName.isEmpty ? 'N.G.N. Member' : displayName,
        'avatar_url': avatar.isEmpty ? null : avatar,
      });
      if (mounted) {
        setState(() {
          joined = true;
          loading = false;
          busy = false;
          error = null;
          notice = null;
        });
      }
    } catch (saveError) {
      final message = saveError.toString().toLowerCase();
      final networkUnavailable = message.contains('failed host lookup') ||
          message.contains('socketexception') ||
          message.contains('network is unreachable') ||
          message.contains('connection timed out') ||
          message.contains('connection refused');
      if (mounted) {
        setState(() {
          loading = false;
          busy = false;
          if (networkUnavailable) {
            // A valid signed-in session can still open the device-only message
            // archive when Supabase cannot be reached.
            joined = true;
            error = null;
            notice = null;
          } else {
            error = 'Your account is signed in, but your Community profile could not be saved: $saveError';
          }
        });
      }
    }
  }

  Future<void> _submit() async {
    if (busy) return;
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmation = confirmPasswordController.text;

    setState(() {
      busy = true;
      error = null;
      notice = null;
    });

    try {
      if (isPasswordRecovery) {
        if (password.length < 8) {
          throw const AuthException('Your new password must be at least 8 characters.');
        }
        if (password != confirmation) {
          throw const AuthException('The passwords do not match.');
        }
        await supabase.auth.updateUser(UserAttributes(password: password));
        if (mounted) {
          setState(() {
            isPasswordRecovery = false;
            busy = false;
            notice = 'Your password has been updated. You can now continue to the community.';
          });
        }
        final user = supabase.auth.currentUser;
        if (user != null) await _saveProfile(user);
        return;
      }

      if (email.isEmpty || !email.contains('@')) {
        throw const AuthException('Enter a valid email address.');
      }

      if (isResetRequest) {
        await supabase.auth.resetPasswordForEmail(
          email,
          redirectTo: callbackUrl,
        );
        if (mounted) {
          setState(() {
            busy = false;
            notice = 'If an account exists for that email, a password reset link has been sent. Check your inbox.';
          });
        }
        return;
      }

      if (password.length < 8) {
        throw const AuthException('Your password must be at least 8 characters.');
      }

      if (isSignUp) {
        if (password != confirmation) {
          throw const AuthException('The passwords do not match.');
        }
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: callbackUrl,
        );
        if (response.session != null && response.user != null) {
          await _saveProfile(response.user!);
        } else if (mounted) {
          setState(() {
            busy = false;
            notice = 'Account created. Please check your email and confirm your address before signing in.';
          });
        }
      } else {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user != null) await _saveProfile(response.user!);
      }
    } on AuthException catch (authError) {
      if (mounted) {
        setState(() {
          busy = false;
          error = authError.message;
        });
      }
    } catch (submitError) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Unable to complete this request: $submitError';
        });
      }
    } finally {
      if (mounted && busy) setState(() => busy = false);
    }
  }

  void _switchMode({bool signUp = false, bool reset = false}) {
    setState(() {
      isSignUp = signUp;
      isResetRequest = reset;
      isPasswordRecovery = false;
      error = null;
      notice = null;
      passwordController.clear();
      confirmPasswordController.clear();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (joined) return const CommunityChatPage();

    final title = isPasswordRecovery
        ? 'Create a new password'
        : isResetRequest
            ? 'Reset your password'
            : isSignUp
                ? 'Create your community account'
                : 'Welcome to the Community';

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
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    isPasswordRecovery
                        ? 'Enter and confirm your new password.'
                        : isResetRequest
                            ? 'Enter the email address linked to your account. We will send a password reset link.'
                            : 'Use your email address and password to join the N.G.N. Community.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  if (!isPasswordRecovery)
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (!isPasswordRecovery) const SizedBox(height: 14),
                  if (!isResetRequest)
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autofillHints: isPasswordRecovery
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: isPasswordRecovery ? 'New password' : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => obscurePassword = !obscurePassword),
                          icon: Icon(obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                  if (!isResetRequest) const SizedBox(height: 14),
                  if (isSignUp || isPasswordRecovery)
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: busy ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(busy
                          ? 'Please wait...'
                          : isPasswordRecovery
                              ? 'Update password'
                              : isResetRequest
                                  ? 'Send reset link'
                                  : isSignUp
                                      ? 'Create account'
                                      : 'Sign in'),
                    ),
                  ),
                  if (!isPasswordRecovery && !isResetRequest && !isSignUp)
                    TextButton(
                      onPressed: busy ? null : () => _switchMode(reset: true),
                      child: const Text('Forgot password?'),
                    ),
                  if (!isPasswordRecovery && !isResetRequest)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => _switchMode(signUp: !isSignUp),
                      child: Text(isSignUp
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account'),
                    ),
                  if (isResetRequest)
                    TextButton(
                      onPressed: busy ? null : () => _switchMode(),
                      child: const Text('Back to sign in'),
                    ),
                  if (notice != null) ...[
                    const SizedBox(height: 10),
                    Text(notice!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
      ),
    );
  }
}

class CommunityChatPage extends StatefulWidget{const CommunityChatPage({super.key});@override State<CommunityChatPage> createState()=>_CommunityChatPageState();}
class _CommunityChatPageState extends State<CommunityChatPage>{
  final CommunityArchiveService _archive=CommunityArchiveService.instance;
  List<Map<String,dynamic>> _archivedRows=[];
  bool _archiveReady=false;
  StreamSubscription<List<Map<String,dynamic>>>? _viewsSubscription;
  final Map<String,int> _seenCounts={};
  bool _isAdmin=false;
  bool _viewSyncInProgress=false;
  final Set<String> _viewedMessageIds={};
  final supabase=Supabase.instance.client,message=TextEditingController(),recorder=AudioRecorder(),player=AudioPlayer(),chatScroll=ScrollController();
  bool recording=false,sending=false,_sendInFlight=false;int recordSeconds=0;Timer? timer;String? playingId;Map<String,dynamic>? replyingTo;String? myName;String? myAvatarUrl;String communityMode='open';
@override void initState(){super.initState();InAppNotificationService.instance.markCommunityRead();_loadArchive();_loadMyName();_loadCommunityMode();_loadAdminStatus();_viewsSubscription=messageViews.listen((rows){if(!mounted)return;setState((){_seenCounts.clear();for(final row in rows){final id=row['message_id']?.toString();if(id!=null)_seenCounts[id]=(_seenCounts[id]??0)+1;}});});}
  Future<void> _loadArchive()async{try{final rows=await _archive.loadMessages();if(mounted)setState(()=>_archivedRows=rows);}catch(_){}finally{if(mounted)setState(()=>_archiveReady=true);}}
  Future<void> _loadCommunityMode()async{try{final r=await supabase.from('app_settings').select('value').eq('id','community_chat').maybeSingle();final value=r?['value'];final mode=value?['mode']?.toString();if(mounted)setState(()=>communityMode=mode??'open');}catch(_){/* Keep the default mode while offline; cached messages remain readable. */}}
  Future<void> _loadMyName()async{final user=supabase.auth.currentUser;if(user==null||user.isAnonymous)return;try{final r=await supabase.from('profiles').select('display_name,avatar_url').eq('id',user.id).maybeSingle();if(!mounted)return;setState((){myName=r?['display_name']?.toString();myAvatarUrl=r?['avatar_url']?.toString();});if((myName??'').trim().isEmpty)WidgetsBinding.instance.addPostFrameCallback((_)=>_editMyName(required:true));}catch(_){/* Profile details can be refreshed when the connection returns. */}}
  Future<void> _editMyName({bool required=false})async{final user=supabase.auth.currentUser;if(user==null)return;final c=TextEditingController(text:myName??'');final value=await showDialog<String>(context:context,barrierDismissible:!required,builder:(context)=>PopScope(canPop:!required,child:AlertDialog(title:const Text('Your Community name'),content:TextField(controller:c,autofocus:true,maxLength:40,decoration:const InputDecoration(hintText:'Enter the name people will see',border:OutlineInputBorder())),actions:[if(!required)TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,c.text.trim()),child:const Text('Save name'))])));c.dispose();if(value==null||value.trim().length<2){if(required&&mounted)_editMyName(required:true);return;}await supabase.from('profiles').update({'display_name':value.trim()}).eq('id',user.id);if(mounted)setState(()=>myName=value.trim());}
  Stream<List<Map<String,dynamic>>> get messages=>supabase.from('community_messages').stream(primaryKey:['id']).order('created_at', ascending: true).limit(100).map((rows)=>rows.map((r)=>Map<String,dynamic>.from(r)).toList());
  Stream<List<Map<String,dynamic>>> get messageViews=>supabase.from('community_message_views').stream(primaryKey:['id']).order('viewed_at',ascending:true).limit(5000).map((rows)=>rows.map((r)=>Map<String,dynamic>.from(r)).toList());
  Future<void> _loadAdminStatus()async{final id=supabase.auth.currentUser?.id;if(id==null)return;try{final row=await supabase.from('admin_members').select('user_id').eq('user_id',id).maybeSingle();if(mounted)setState(()=>_isAdmin=row!=null);}catch(_){} }
  Future<void> _recordMessageViewed(String messageId) async {
    final user = supabase.auth.currentUser;
    if (user == null || user.isAnonymous || !_viewedMessageIds.add(messageId)) return;
    try {
      await supabase.from('community_message_views').insert({
        'message_id': messageId,
        'viewer_id': user.id,
      });
    } on PostgrestException catch (error) {
      if (error.code == '23505') return;
      _viewedMessageIds.remove(messageId);
      await _queuePendingMessageView(user.id, messageId);
    } catch (_) {
      _viewedMessageIds.remove(messageId);
      await _queuePendingMessageView(user.id, messageId);
    }
  }

  Future<void> _queuePendingMessageView(String userId, String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'ngn_pending_message_views_$userId';
    final pending = (prefs.getStringList(key) ?? <String>[]).toSet()
      ..add(messageId);
    await prefs.setStringList(key, pending.toList());
  }

  Future<void> _flushPendingMessageViews() async {
    final user = supabase.auth.currentUser;
    if (user == null || user.isAnonymous || _viewSyncInProgress) return;
    _viewSyncInProgress = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'ngn_pending_message_views_${user.id}';
      final pending = (prefs.getStringList(key) ?? <String>[]).toSet();
      final remaining = <String>[];
      for (final id in pending) {
        try {
          await supabase.from('community_message_views').insert({
            'message_id': id,
            'viewer_id': user.id,
          });
          _viewedMessageIds.add(id);
        } on PostgrestException catch (error) {
          if (error.code == '23505') {
            _viewedMessageIds.add(id);
          } else {
            remaining.add(id);
          }
        } catch (_) {
          remaining.add(id);
        }
      }
      if (remaining.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setStringList(key, remaining);
      }
    } finally {
      _viewSyncInProgress = false;
    }
  }

  Future<void> _showMessageViewers(String messageId)async{try{final views=await supabase.from('community_message_views').select('viewer_id,viewed_at').eq('message_id',messageId).order('viewed_at',ascending:false);final ids=views.map((r)=>r['viewer_id'].toString()).toSet().toList();if(!mounted)return;if(ids.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('No one has viewed this message yet.')));return;}final profiles=await supabase.from('profiles').select('id,display_name,avatar_url').inFilter('id',ids);final byId={for(final p in profiles)p['id'].toString():p};if(!mounted)return;showModalBottomSheet(context:context,showDragHandle:true,builder:(context)=>SafeArea(child:ListView(shrinkWrap:true,padding:const EdgeInsets.fromLTRB(16,8,16,24),children:[Text('${ids.length} people viewed this message',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:10),...views.map((v){final p=byId[v['viewer_id'].toString()];return ListTile(leading:CircleAvatar(backgroundImage:(p?['avatar_url']?.toString().isNotEmpty??false)?NetworkImage(p!['avatar_url'].toString()):null,child:(p?['avatar_url']?.toString().isNotEmpty??false)?null:const Icon(Icons.person_outline)),title:Text(p?['display_name']?.toString()??'N.G.N. Member'),subtitle:Text('Viewed ${DateTime.tryParse(v['viewed_at'].toString())?.toLocal().toString().substring(0,16)??''}'));})])));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not load viewers: $e')));}}
  void scrollToLatest(){WidgetsBinding.instance.addPostFrameCallback((_){if(chatScroll.hasClients)chatScroll.animateTo(chatScroll.position.maxScrollExtent,duration:const Duration(milliseconds:280),curve:Curves.easeOut);});}
  Map<String,dynamic>? replyTarget(List<Map<String,dynamic>> rows,dynamic replyToId){if(replyToId==null)return null;for(final row in rows){if(row['id']==replyToId)return row;}return null;}
  Future<Map<String,dynamic>?> profileFor(String id)async{final r=await supabase.from('profiles').select('display_name,avatar_url').eq('id',id).maybeSingle();return r==null?null:Map<String,dynamic>.from(r);}
  Future<void> sendText()async{if(communityMode=='locked'||_sendInFlight)return;final text=message.text.trim(),user=supabase.auth.currentUser;if(text.isEmpty||user==null||sending)return;_sendInFlight=true;setState(()=>sending=true);try{await supabase.from('community_messages').insert({'author_id':user.id,'message_type':'text','body':text,'reply_to_id':replyingTo?['id']});if(message.text.trim()==text)message.clear();if(mounted)setState(()=>replyingTo=null);}on PostgrestException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}finally{_sendInFlight=false;if(mounted)setState(()=>sending=false);}}
  Future<void> toggleRecording()async{if(communityMode=='locked')return;if(recording){await finishRecording();return;}if(!await recorder.hasPermission()){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Microphone permission is needed for voice notes.')));return;}final dir=await getTemporaryDirectory(),path='${dir.path}/ngn_${DateTime.now().millisecondsSinceEpoch}.m4a';await recorder.start(const RecordConfig(encoder:AudioEncoder.aacLc,bitRate:48000,sampleRate:24000,numChannels:1,noiseSuppress:true),path:path);setState((){recording=true;recordSeconds=0;});timer=Timer.periodic(const Duration(seconds:1),(t){if(!mounted)return;setState(()=>recordSeconds++);if(recordSeconds>=120)finishRecording();});}
  Future<void> finishRecording()async{timer?.cancel();final seconds=recordSeconds.clamp(1,120),path=await recorder.stop();if(mounted)setState(()=>recording=false);if(path==null)return;final user=supabase.auth.currentUser;if(user==null)return;setState(()=>sending=true);final storagePath='${user.id}/${DateTime.now().millisecondsSinceEpoch}.m4a';try{await supabase.storage.from('community-voice').upload(storagePath,File(path),fileOptions:const FileOptions(contentType:'audio/mp4'));try{await supabase.from('community_messages').insert({'author_id':user.id,'message_type':'voice','voice_path':storagePath,'voice_duration_seconds':seconds,'reply_to_id':replyingTo?['id']});if(mounted)setState(()=>replyingTo=null);}catch(_){await supabase.storage.from('community-voice').remove([storagePath]);rethrow;}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Voice note could not be sent: $e')));}finally{try{await File(path).delete();}catch(_){}if(mounted)setState(()=>sending=false);}}
  Future<void> playVoice(Map<String,dynamic> row)async{final path=row['voice_path']?.toString(),id=row['id']?.toString();if(path==null||id==null)return;if(playingId==id){await player.stop();if(mounted)setState(()=>playingId=null);return;}try{var local=await _archive.cachedMediaPath(id);local??=await _archive.cacheMedia(messageId:id,bucket:'community-voice',storagePath:path,extension:'m4a');await player.play(DeviceFileSource(local));}catch(_){final url=await supabase.storage.from('community-voice').createSignedUrl(path,3600);await player.play(UrlSource(url));}if(mounted)setState(()=>playingId=id);}
  Future<void> deleteOwn(Map<String,dynamic> row)async{final voicePath=row['voice_path']?.toString(),filePath=row['file_path']?.toString(),id=row['id']?.toString();await supabase.from('community_messages').delete().eq('id',row['id']);if(id!=null)await _archive.deleteMessageLocally(id);if(voicePath!=null)await supabase.storage.from('community-voice').remove([voicePath]);if(filePath!=null)await supabase.storage.from('ngn-media').remove([filePath]);}
  String? communityFileUrl(Map<String,dynamic> row){final path=row['file_path']?.toString();if(path==null||path.isEmpty)return null;return supabase.storage.from('ngn-media').getPublicUrl(path);}
  Future<void> downloadCommunityFile(Map<String,dynamic> row)async{final id=row['id']?.toString(),path=row['file_path']?.toString();if(id==null||path==null)return;try{final name=row['file_name']?.toString()??'attachment.bin';final ext=name.contains('.')?name.split('.').last:'bin';var local=await _archive.cachedMediaPath(id);local??=await _archive.cacheMedia(messageId:id,bucket:'ngn-media',storagePath:path,extension:ext);await OpenFilex.open(local);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save or open this file: $e')));}}
  void previewCommunityImage(Map<String,dynamic> row,String url,String name){final id=row['id']?.toString(),storagePath=row['file_path']?.toString();final extension=name.contains('.')?name.split('.').last:'jpg';final cached=id==null||storagePath==null?Future<String?>.value(null):_archive.cachedMediaPath(id).then((path)async=>path??await _archive.cacheMedia(messageId:id,bucket:'ngn-media',storagePath:storagePath,extension:extension)).catchError((_)=>'');showDialog(context:context,builder:(dialogContext)=>Dialog(backgroundColor:Colors.black,insetPadding:const EdgeInsets.all(8),child:Stack(children:[InteractiveViewer(minScale:0.8,maxScale:4,child:Center(child:FutureBuilder<String?>(future:cached,builder:(context,snapshot){final local=snapshot.data;return local!=null&&local.isNotEmpty?Image.file(File(local),fit:BoxFit.contain,width:double.infinity,height:MediaQuery.of(dialogContext).size.height*0.88):Image.network(url,fit:BoxFit.contain,width:double.infinity,height:MediaQuery.of(dialogContext).size.height*0.88,errorBuilder:(_,__,___)=>const Center(child:Padding(padding:EdgeInsets.all(30),child:Text('Image could not be loaded.',style:TextStyle(color:Colors.white)))));}))),Positioned(top:8,right:8,child:IconButton.filled(onPressed:()=>Navigator.pop(dialogContext),icon:const Icon(Icons.close_rounded),tooltip:'Close image'))])));}
  Widget fileAttachment(Map<String,dynamic> row,bool mine){final name=row['file_name']?.toString()??'Community file';final mime=row['file_mime_type']?.toString().toLowerCase()??'';final isImage=mime.startsWith('image/');final url=communityFileUrl(row);final size=(row['file_size_bytes'] as num?)?.toInt();final sizeLabel=size==null?'Tap to download':'${(size/1024/1024).toStringAsFixed(1)} MB • Tap to download';if(isImage&&url!=null){return GestureDetector(onTap:()=>previewCommunityImage(row,url,name),child:ClipRRect(borderRadius:BorderRadius.circular(11),child:Image.network(url,width:260,height:190,fit:BoxFit.contain,loadingBuilder:(context,child,progress)=>progress==null?child:Container(width:260,height:150,alignment:Alignment.center,color:Colors.black12,child:const CircularProgressIndicator()),errorBuilder:(_,__,___)=>Container(width:260,height:120,color:Colors.black12,alignment:Alignment.center,child:const Icon(Icons.broken_image_outlined,size:38)))));}return InkWell(onTap:()=>downloadCommunityFile(row),child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:(mine?Colors.white:const Color(0xFF0B5ED7)).withValues(alpha:.12),borderRadius:BorderRadius.circular(10)),child:Row(children:[Icon(Icons.insert_drive_file_rounded,color:mine?Colors.white:const Color(0xFF0B5ED7),size:28),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,color:mine?Colors.white:null)),const SizedBox(height:3),Text(sizeLabel,style:TextStyle(fontSize:11,color:mine?Colors.white70:null))])),Icon(Icons.download_rounded,color:mine?Colors.white:const Color(0xFF0B5ED7))])));}
  Future<void> report(Map<String,dynamic> row)async{final user=supabase.auth.currentUser;if(user==null)return;await supabase.from('community_reports').insert({'reporter_id':user.id,'message_id':row['id'],'reason':'Reported from community chat'});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Message reported to N.G.N. administrators.')));}
  Future<void> _signOutFromCommunity()async{await supabase.auth.signOut();if(!mounted)return;Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>const CommunityJoinPage()));}
  @override void dispose(){_viewsSubscription?.cancel();timer?.cancel();message.dispose();recorder.dispose();player.dispose();chatScroll.dispose();super.dispose();}
  @override Widget build(BuildContext context){final me=supabase.auth.currentUser?.id;return Scaffold(appBar:AppBar(title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('N.G.N. Community'),if(myName!=null)Text(myName!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.normal))]),actions:[if(myAvatarUrl!=null&&myAvatarUrl!.isNotEmpty)Padding(padding:const EdgeInsets.symmetric(horizontal:6),child:CircleAvatar(radius:15,backgroundImage:NetworkImage(myAvatarUrl!))),IconButton(onPressed:()=>_editMyName(),tooltip:'Change my Community name',icon:const Icon(Icons.badge_outlined)),IconButton(onPressed:_signOutFromCommunity,tooltip:'Sign out of Community',icon:const Icon(Icons.logout_rounded))]),body:Column(children:[
    Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:16,vertical:9),color:const Color(0xFFD4AF37).withValues(alpha:.12),child:Text(communityMode=='locked'?'Community chat is currently closed. You can read previous messages and check back for the next N.G.N. session.':communityMode=='meeting'?'N.G.N. Community meeting is now open • Fellowship with kindness':'Fellowship with kindness • Messages are automatically removed after 30 days',textAlign:TextAlign.center,style:const TextStyle(fontSize:12))),
    const CommunityStoriesWidget(),
    Expanded(child:Container(
       color: const Color(0xFFF4F6FA),
       child:StreamBuilder<List<Map<String,dynamic>>>(stream:messages,builder:(context,snapshot){if(snapshot.hasData){InAppNotificationService.instance.markCommunityRead();unawaited(_archive.cacheMessages(snapshot.data!));unawaited(_flushPendingMessageViews());}final sourceRows=snapshot.hasData?snapshot.data!:_archivedRows;final rows=_archive.filterVisibleMessages(sourceRows);if(!_archiveReady)return const Center(child:CircularProgressIndicator());if(rows.isEmpty)return Center(child:Text(snapshot.hasError?'No saved messages yet. Connect to load the Community.':'Start the conversation. 👋'));scrollToLatest();return ListView.builder(controller:chatScroll,padding:const EdgeInsets.all(14),itemCount:rows.length,itemBuilder:(context,index){final row=rows[index],mine=row['author_id']==me;return VisibilityDetector(key:Key("community-message-${row['id']}"),onVisibilityChanged:(info){if(info.visibleFraction>=0.6&&row['author_id']!=me)unawaited(_recordMessageViewed(row['id'].toString()));},child:FutureBuilder<Map<String,dynamic>?>(future:profileFor(row['author_id'].toString()),builder:(context,n)=>Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:GestureDetector(onLongPress:()=>showModalBottomSheet(context:context,builder:(_)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[ListTile(leading:const Icon(Icons.reply_rounded),title:const Text('Reply'),onTap:(){Navigator.pop(context);setState(()=>replyingTo=row);}),if(mine)ListTile(leading:const Icon(Icons.delete_outline),title:const Text('Delete my message'),onTap:(){Navigator.pop(context);deleteOwn(row);}),if(!mine)ListTile(leading:const Icon(Icons.flag_outlined),title:const Text('Report to admin'),onTap:(){Navigator.pop(context);report(row);})]))),child:Container(constraints:const BoxConstraints(maxWidth:310),margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:mine?const Color(0xFF0B5ED7):Theme.of(context).cardColor,borderRadius:BorderRadius.circular(16),border:mine?null:Border.all(color:Theme.of(context).dividerColor)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(row['reply_to_id']!=null)Builder(builder:(context){final target=replyTarget(rows,row['reply_to_id']);final preview=target==null?'Original message unavailable':target['message_type']=='voice'?'Voice note':target['message_type']=='file'?'File: ${target['file_name']??'Attachment'}':(target['body']?.toString()??'Message');return Container(width:double.infinity,margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:9,vertical:7),decoration:BoxDecoration(color:(mine?Colors.white:const Color(0xFF0B5ED7)).withValues(alpha:.12),borderRadius:BorderRadius.circular(9),border:Border(left:BorderSide(color:mine?const Color(0xFFD4AF37):const Color(0xFF0B5ED7),width:3))),child:Row(children:[const Icon(Icons.reply_rounded,size:14),const SizedBox(width:6),Expanded(child:Text(preview,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,fontStyle:FontStyle.italic)))]));}),Row(children:[CircleAvatar(radius:12,backgroundImage:(n.data?['avatar_url']?.toString().isNotEmpty??false)?NetworkImage(n.data!['avatar_url'].toString()):null,child:(n.data?['avatar_url']?.toString().isNotEmpty??false)?null:const Icon(Icons.person_rounded,size:14)),const SizedBox(width:7),Expanded(child:Text(n.data?['display_name']?.toString()??'N.G.N. Member',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:mine?const Color(0xFFD4AF37):const Color(0xFF0B5ED7))))]),const SizedBox(height:5),if(row['message_type']=='voice')InkWell(onTap:()=>playVoice(row),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(playingId==row['id']?Icons.stop_circle_outlined:Icons.play_circle_outline,color:mine?Colors.white:const Color(0xFF0B5ED7)),const SizedBox(width:8),Text('Voice note • ${row['voice_duration_seconds']??0}s',style:TextStyle(color:mine?Colors.white:null))]))else if(row['message_type']=='file')fileAttachment(row,mine)else Text(row['body']?.toString()??'',style:TextStyle(color:mine?Colors.white:null,height:1.35)),if(mine&&_isAdmin)Align(alignment:Alignment.centerRight,child:InkWell(onTap:()=>_showMessageViewers(row['id'].toString()),borderRadius:BorderRadius.circular(12),child:Padding(padding:const EdgeInsets.only(top:7),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.visibility_outlined,size:13,color:Colors.white70),const SizedBox(width:4),Text('${_seenCounts[row['id'].toString()]??0} seen',style:const TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w600))])) ))]))))));});}))),
    SafeArea(top:false,child:Column(mainAxisSize:MainAxisSize.min,children:[if(replyingTo!=null)Container(margin:const EdgeInsets.fromLTRB(10,6,10,0),padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(12)),child:Row(children:[const Icon(Icons.reply_rounded,size:18),const SizedBox(width:8),Expanded(child:Text(replyingTo!['message_type']=='voice'?'Replying to voice note':replyingTo!['message_type']=='file'?'Replying to file: ${replyingTo!['file_name']??'Attachment'}':(replyingTo!['body']?.toString()??'Replying to message'),maxLines:1,overflow:TextOverflow.ellipsis)),IconButton(onPressed:()=>setState(()=>replyingTo=null),icon:const Icon(Icons.close_rounded),visualDensity:VisualDensity.compact)])),Padding(padding:const EdgeInsets.fromLTRB(10,8,10,10),child:Row(children:[IconButton.filledTonal(onPressed:sending||communityMode=='locked'?null:toggleRecording,icon:Icon(recording?Icons.stop_rounded:Icons.mic_none_rounded),tooltip:recording?'Stop voice note':'Record voice note'),const SizedBox(width:8),Expanded(child:TextField(controller:message,enabled:!recording&&communityMode!='locked',maxLength:2000,minLines:1,maxLines:4,decoration:InputDecoration(counterText:'',hintText:communityMode=='locked'?'Community chat is closed':recording?'Recording… $recordSeconds/120s':'Message the community',border:OutlineInputBorder(borderRadius:BorderRadius.circular(22))))),const SizedBox(width:8),IconButton.filled(onPressed:sending||recording||communityMode=='locked'?null:sendText,icon:sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded))]))]))
  ]));}
}
