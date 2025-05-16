import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:mekyas_tawazoun/screens/splash_screen.dart';

// create credentials
  const _credentials = r'''
  {
  "type": "service_account",
  "project_id": "mekyas-tawazoun",
  "private_key_id": "22898178250d839ba8542b29949e65b376e49e87",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCyci35qxRhBW5a\ntnYUOX7GIPBohw3uhAU08Dseczlsr7bkLSOzTLJ7z3AAT5QKjYL+pbA9ap/iC+PD\nSCW+DjrzbSGHkuP9AqqAhEUs+0jiXtznB8E0xYfNH3uPBp5ucpLI3aZ/HeiI1wYm\nnUF13RvHCEKs6754xVvOTr4D//sPDBa9mfpdREDCZ1q8wvmzpAjleAYXv/3J8NlQ\n03EHoZ+hSj6EDnn1ADiCIy0ZhFVxZr59XDhmuY5HTHyAVgvLm+j9H58FxWxmp3kZ\nTLjEm4COge47ngUGl/5mfkeV6b6Lhe4sZ01YMYd8S9W3IhubPzVWOUdMMpxiZcDT\n28N601X1AgMBAAECggEAKlOM9jCPN+gq4ddvsKJmoKZFf/Ww50dnWMQ2saVRFKel\nMQBH/IqPt3Bft6MokUw5qx8v65Fz9REu6C4fzbHgZ8cV8et0qpnMSYmWQvIjupYX\nvbEIMfU8nfn+u9EtGTOR/5UbngFBG9ws+FHKqiNVKGOcNRoB5vGhMhFZXueD7HBj\nGh6iaFGiJAXPQH9vn4mJeSh0ThgG9FpPofhqphAu9QyrqG0Ct8CGQ7A4O7gfs4Hx\n5YQcsou5juJuMUy2vfuZ2iGvSLaTWzz3noHuLH2nII9VSQUzGCJl7qGg6pNulgxT\nUYGNtykH7y5SW7ZujqnFzVSRRgc1S6n8cLWQFCg5QQKBgQDg2jbhNVv8dRBOEseM\nQAzQVWcQD63qSfrhJ9R9H+iFWl+Zixl0d9pO9IVvzfiYR50dEU2wgAAUqpeha6dH\nExuKNS37Erpg4407toogPdJZ0xABMId7u4KST1C5W9Nar7f8XFZS63zMh2nzpyd+\nSu3/ZQ494NyYZOgae49Nqo+9ZQKBgQDLKkmc893iWq4hIQloO0Q0OFtwi/nzBKAN\n7TcRC9MKN3FHGftG6+CH8SSIrgl3tLhdd1qYMa5sT+o2PMSjPuCUs+Sj3ElHEIsm\nH+wzNNvVKT+JEyZHM0/RWo6cXqygu+xbA+C0uA1+M5KxyxAAnbq3LwiTO5pWWbE6\nEhxTqbC1UQKBgGlNSI5H0wB0QmKN4O4JwPaASHf5H9WtN9TiNl0y6E4reMILpqwo\nxRBc63Dk4RtPzoCibePOzjrfeYubQwfCJw+ewB3pM2fUqXvhjOZ0jWKLud8Uvx5v\nPkMO6hskqeK6kEubYsIKjrOqZzA4hAJdTQBibz0DZcvo1doxK3eP/SkRAoGAF/56\niyrR/bWv8wGv1ruJJpGxWu1tK6JUNNDbPAwldINvwXH0F0AsWGHGas4DGDwjugYq\nkObtLqWRh65NmuoGJAnK6v9NODNf+7SxdKq9e8NPWaUFVEtfFd6YESetQ55uH6Gp\nnC5QiaMVpCHTVf9K2e+YF6tmYuRc5frVlZvo3sECgYAoV7k8tRPo50OqgBg89rjp\nrfTi1Oo+BqpXLzEglENhGaG9Tkk2a5URC5RZrCqueLTCXjqhst8zkIL4TWWj1KPa\nKjMDxopwXLON/evQTIkprwQsJjNAHRBlew3Fgh5lZg9bYUsB6hjNNHl2RHqrJxYA\nwnlvHbDGvh3wUlpCtMBugQ==\n-----END PRIVATE KEY-----\n",
  "client_email": "mekyas-tawazoun-app@mekyas-tawazoun.iam.gserviceaccount.com",
  "client_id": "106642882816028459245",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/mekyas-tawazoun-app%40mekyas-tawazoun.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
  ''';

  // spreadsheet id

  const _spreadsheetId = '13iEnBEY7eM28njtxr8i1108zh6Lyk4iwYkC7ITBfnQU';


void main() async {
  // init Gsheet
  final _gsheets = GSheets(_credentials);

  // fetch spreadsheet
  final _spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);

  // get worksheet by title
  final _worksheet = await _spreadsheet.worksheetByTitle('Worksheet1');
  
  // updating a cell
  await _worksheet!.values.insertValue('Hello World',row: 1, column: 1);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
