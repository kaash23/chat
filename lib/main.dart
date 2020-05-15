import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<FirebaseUser> _handleSignIn() async {
  final GoogleSignInAccount googleUser = await _googleSingIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;
  print("signed in " + user.displayName);
  return user;
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

final ThemeData kIOSTheme = ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

final _googleSingIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;

 _ensureLoggedIn() async{
  GoogleSignInAccount user = _googleSingIn.currentUser;
  if(user == null)
    user = await _googleSingIn.signInSilently();
  if(user == null)
    user = await _googleSingIn.signIn();
  if(await _auth.currentUser() == null){
    _handleSignIn();
  }
}

_handleSubmitted(String text) async {
  await _ensureLoggedIn();
  _sendMessage(text: text);
}

void _sendMessage({String text, String imgUrl}){
  Firestore.instance.collection("messages").add(
    {
      "text" : text,
      "imgUrl" : imgUrl,
      "senderName" : _googleSingIn.currentUser.displayName,
      "senderPhotoUrl" : _googleSingIn.currentUser.photoUrl
    }
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chat App",
      debugShowCheckedModeBanner: false,
      theme: Theme.of(context).platform == TargetPlatform.iOS ?
          kIOSTheme : kDefaultTheme,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Chat App"),
          centerTitle: true,
          elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: <Widget>[
                  ChatMessage(),
                  ChatMessage(),
                  ChatMessage()
                ],
              ),
            ),
            Divider(
              height: 1.0,
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor
              ),
              child: TextComposer(),
            ),
          ],
        ),
      ),
    );
  }
}

class TextComposer extends StatefulWidget {
  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {

  final _textController = TextEditingController();
  bool _isComposing = false;

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: Theme
          .of(context)
          .accentColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: Theme
            .of(context)
            .platform == TargetPlatform.iOS ?
        BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[200]))
        ) : null,
        child: Row(
          children: <Widget>[
            Container(
                child: IconButton(icon: Icon(Icons.photo_camera),
                  onPressed: () {},)
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration.collapsed(
                    hintText: "Enviar uma Mensagem"),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: (text){
                  _handleSubmitted(text);
                },
              ),
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme
                    .of(context)
                    .platform == TargetPlatform.iOS ?
                CupertinoButton(
                  child: Text("Enviar"),
                  onPressed: _isComposing ? () {
                    _handleSubmitted(_textController.text);
                  } : null,
                ) :
                IconButton(icon: Icon(Icons.send),
                  onPressed: _isComposing ? () {
                    _handleSubmitted(_textController.text);
                  } : null,)
            ),
          ],
        ),
      ),
    );
  }
}


class ChatMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage("https://scontent-gru1-1.xx.fbcdn.net/v/t1.0-9/22688350_1584829164902439_2011451994789882922_n.jpg?_nc_cat=108&_nc_sid=a4a2d7&_nc_ohc=idi5RWmpx40AX-cycwe&_nc_ht=scontent-gru1-1.xx&oh=f2eee5fa8272aad027e7125dce63800d&oe=5ED583E0"),
            ),
          ),
          Expanded (
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Gustavo",
                  style: Theme.of(context).textTheme.subhead,
                ),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text("teste"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

