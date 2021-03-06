import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';


dynamic date;



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



void _sendMessage({String text, String imgUrl}){

  Firestore.instance.collection("messages").add(
    {
      "text" : text,
      "imgUrl" : imgUrl,
      "senderName" : _googleSingIn.currentUser.displayName,
      "senderPhotoUrl" : _googleSingIn.currentUser.photoUrl,
      "sendDate" : date.toString()
    }
  );
}

_handleSubmitted(String text) async {
  await _ensureLoggedIn();
  _sendMessage(text: text);
  date = DateFormat.jms().format(DateTime.now());
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
              child: StreamBuilder(
                stream: Firestore.instance.collection("messages").orderBy("sendDate").snapshots(),
                builder: (context, snapshot){
                  switch ( snapshot.connectionState ){
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    default:
                      return ListView.builder(
                        reverse: true,
                        itemCount: snapshot.data.documents.length,
                        itemBuilder: (context, index){
                          List r = snapshot.data.documents.reversed.toList();
                          return ChatMessage(r[index].data);
                        },
                      );
                  }
                }
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
//Campo de digitação de mensagem
class TextComposer extends StatefulWidget {
  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {

  final _textController = TextEditingController();
  bool _isComposing = false;

  void _reset(){
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
  }

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
                onSubmitted: (text){
                  _handleSubmitted(_textController.text);
                  _reset();
                },
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
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
                    _reset();
                  } : null,
                ) :
                IconButton(icon: Icon(Icons.send),
                  onPressed: _isComposing ? () {
                    _handleSubmitted(_textController.text);
                    _reset();
                    //mudar o metodo para que seja exibido a hora simplificada
                    //no app
                  } : null,
                )
            ),
          ],
        ),
      ),
    );
  }
}


class ChatMessage extends StatelessWidget {

   final Map<String, dynamic> data;

   ChatMessage(this.data);

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
              backgroundImage: NetworkImage(data["senderPhotoUrl"]),
            ),
          ),
          Expanded (
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      data["senderName"],
                      style: Theme.of(context).textTheme.subhead,
                    ),
                    Container(
                      child: Padding(
                        padding: EdgeInsets.only(left: 150.0),
                        child: Text(
                          data["sendDate"],
                          style: TextStyle(fontSize: 10.0, color: Colors.grey),

                        ),
                      ),
                    )
                    //METODO JA IMPLEMENTADO PARA EXIBIR A DATA E HORA DA MSG
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: data["imgUrl"] != null ?
                    Image.network(data["imgURL"], width: 250.0) :
                    Text(data["text"]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

