import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reusable_widgets/reusable_widgets.dart';
import 'add_new_theme.dart';

class ThemesScreen extends StatefulWidget {
  @override
  _ThemesScreenState createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  List<ThemeClass> themes = []; // List to store the retrieved themes
  bool isLoading = true; // Flag to track the loading state

  @override
  void initState() {
    super.initState();
    retrieveThemesFromFirebase();
  }

  void retrieveThemesFromFirebase() async {
    CollectionReference userPreferencesCollection =
    FirebaseFirestore.instance.collection('user_preferences');

    QuerySnapshot querySnapshot = await userPreferencesCollection
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .get();

    DocumentSnapshot documentSnapshot = querySnapshot.docs[0];
    Map<String, List<dynamic>> themesMap =
    Map<String, List<dynamic>>.from(documentSnapshot['Themes']);

    List<ThemeClass> fetchedThemes = themesMap.entries.map((entry) {
      String themeName = entry.key;
      List<dynamic> colors = entry.value;

      Color color1 = Color.fromRGBO(colors[0], colors[1], colors[2], 1);
      Color color2 = Color.fromRGBO(colors[3], colors[4], colors[5], 1);
      Color color3 = Color.fromRGBO(colors[6], colors[7], colors[8], 1);

      return ThemeClass(
        name: themeName,
        color1: color1,
        color2: color2,
        color3: color3,
      );
    }).toList();

    setState(() {
      themes = fetchedThemes;
      isLoading = false; // Set isLoading to false when retrieval is complete
    });
  }


  Future<void> _deleteTheme(String theme) async {
    final userDoc = FirebaseFirestore.instance
        .collection('user_preferences')
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .limit(1);
    final userDocSnapshot = await userDoc.get();
    final userDocRef = userDocSnapshot.docs.first.reference;
    final themesMap = Map<String, dynamic>.from(userDocSnapshot.docs.first.get('Themes') ?? {});
    themesMap.remove(theme);
    await userDocRef.update({'Themes': themesMap});
    retrieveThemesFromFirebase();
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while retrieving themes
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16,),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddNewThemeScreen()),
                  );
                  retrieveThemesFromFirebase(); // Re-fetch the themes from Firebase
                },
                child: Text('Add New Theme'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24), // Increase the padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Add rounded corners
                  ),
                ),
              ),
              const SizedBox(height:16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final theme = themes[themes.length - index - 1];
                  return Card(
                    child: ListTile(
                      title: Text(theme.name),
                      subtitle: Row(
                        children: [
                          ColorBox(color: theme.color1),
                          ColorBox(color: theme.color2),
                          ColorBox(color: theme.color3),
                        ],
                      ),
                      trailing: index != 0 ? IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () async {
                          await _deleteTheme(theme.name);
                        },
                      ) : null,
                    ),
                  );
                },
              )
            ]
        ),
      ),
      )
    );
  }
}

class ColorBox extends StatelessWidget {
  final Color color;

  const ColorBox({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: color,
    );
  }
}
