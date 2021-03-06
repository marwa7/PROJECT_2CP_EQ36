import 'dart:io';

import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:projet_2cp/classes/Groupe.dart';
import 'package:projet_2cp/classes/Historique.dart';
import 'package:projet_2cp/servises/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
class Utilisateur {
  //************************************* Attributs ***************************************************//
  String _id; //Try to make it final
  //String _username;
  String _email;
  String _password;
  String _nom;
  String _prenom;
  String _phone;
  bool _active;
  bool _photo;
  Position _location;
  double _vitesse; //////
  Transport _transport; //////
  List<Vehicule>_listVehicles;
  Historique _historique; //////
  List<Groupe>_list_groupes; /////
  //Boite de reception



  //List message personalisées

  //Auth
  final ServicesAuth _auth = ServicesAuth();

  //DB
  final Firestore _firestore = Firestore.instance;

  //*****************************************Constructors*********************************************************//
  //Creer un nouveau utilisateur
  Utilisateur.neww (String id, String email, String password, String nom,
      String prenom)
  {
    this._id = id;
    this._email = email;
    this._password = password;
    this._nom = nom;
    this._prenom = prenom;
    this._active = true;
    this._historique = new Historique();
    this._list_groupes = new List<Groupe> ();
    this._listVehicles = new List<Vehicule>();
  }

  //Creer un utilisateur a partir d'un doc Firestore
  Utilisateur.old (DocumentReference doc)
  {
    //
  }

  //*********************************************Methods*****************************************************//
  //Create a new User doc of the user
  Future<void> createUserDoc(Utilisateur user) async
  {
    Geolocator location = Geolocator();
    try {
      await _firestore.collection("users")
          .document(user.getId())
          .setData({
        'UID': user.getId(),
        'Nom': user.getNom(),
        'Prenom': user.getPrenom(),
        'email': user.getEmail(),
        //String _username;
        'Password': user.getPassword(),
        'Phone': '',
        'PhotoURL': '', //*****
        //'Historique': '', //*****
        //'BoiteReception': '', //*****
        //'Groupe': '', //*****
        'Active': true,
      })
          .then((_) {
        print('done');
      })
          .catchError((error) {
            print('something went wrong i create user doc');
      });
    }
    catch (e) {
      print(e.toString());
    }
  }
  //------------------------------------------Email--------------------------------------------
  //Change user's password
  Future <void> setEmail(String email) async
  {
    await _auth.changeEmail(email);
    _firestore.collection("users").document(this._id).updateData(
        {
          "Email": email,
        }
    ).then((result) {
      print("Email changed");
      this._email = email;
    }).catchError((error) {
      print("Error" + error.toString());
    });
  }
  //------------------------------------------Password--------------------------------------------
  //Change user's password
  Future <void> setPassword(String oldPassword, String newPassword) async
  {
    if (this._password == oldPassword) {
      await _auth.changePassword(newPassword);
      _firestore.collection("users").document(this._id).updateData(
          {
            "Password": newPassword,
          }
      ).then((result) {
        print("password changed");
        this._password = newPassword;
      }).catchError((error) {
        print("Error" + error.toString());
      });
    }
    else {
      print('Wrong password');
    }
  }
  //Reser the password
  Future<void> recupererMotPasse() async
  {
    await _auth.resetPassword(this._email);
  }
  //------------------------------------------Display name--------------------------------------------
  //Change display name
  void setNomPrenom(String nom, String prenom) {
    if (nom != null) {
      _firestore.collection("users").document(this._id).updateData(
          {
            "Nom": nom,
          }
      ).then((result) {
        this._nom = nom;
        print("Nom change");
      }).catchError((error) {
        print("Error" + error.toString());
      });
    }
    if (prenom != null) {
      _firestore.collection("users").document(this._id).updateData(
          {
            "Prenom": prenom,
          }
      ).then((result) {
        this._prenom = prenom;
        print("Nom change");
      }).catchError((error) {
        print("Error" + error.toString());
      });
    }
  }
  //------------------------------------------Phone--------------------------------------------
  void setPhone(String phone) {
    _firestore.collection("users").document(this._id).updateData(
        {
          "Phone": phone,
        }
    ).then((result) {
      this._phone = phone;
      print("phone number changed");
    }).catchError((error) {
      print("Error" + error.toString());
    });
  }
  //------------------------------------------ActiveStatus--------------------------------------------
  //Change active status
  void changeActiveStatus() {
    _firestore.collection("users").document(this._id).updateData(
        {
          "Active": _active,
        }
    ).then((result) {
      _active = !_active;
      print("Status changed");
    }).catchError((error) {
      print("Error" + error.toString());
    });
  }
  //------------------------------------------Photo--------------------------------------------
  Future<void> setPhoto(String photoURL) async {
    //TODO user's photo (existing ??)
    File file;
    file = await FilePicker.getFile(type: FileType.image);
    _uploadPhoto(file);
    file.copy('user_info/profilePhoto');
    this._photo =  true;
  }
  Future<String> _uploadPhoto(File file) async {
    StorageReference storageReference;
    storageReference = FirebaseStorage.instance.ref().child(this._id+"/"+'profilePhoto');
    final StorageUploadTask uploadTask = storageReference.putFile(file);
    final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
    final String url = (await downloadUrl.ref.getDownloadURL());
  }
  //------------------------------------------Location--------------------------------------------
  Future<void> setLocation()  async  {
    Geolocator geolocator = Geolocator();
    Geoflutterfire geofire =Geoflutterfire();
    _location = await geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((_){
          print('we got cuurent position');
    }).catchError((error){
      print('Error : Couldn\'t get cuurent position'+error);
    });
    GeoFirePoint geopoint = geofire.point(latitude: _location.latitude, longitude: _location.longitude);
    _firestore.collection("users").document(this._id).updateData(
        {
          "Position": geopoint.data,
        }
    ).then((result) {
      print('position set');
    }).catchError((error) {
      print('Error : couldn\'t set position' + error.toString());
    });
  }
  //------------------------------------------Vitesse--------------------------------------------
  void setVitesse()
  {
    double v  = _location.speed;
    _firestore.collection("users").document(this._id).updateData(
        {
          "Vitesse": v,
        }
    ).then((result) {
      print('speed set');
      _vitesse = v;
    }).catchError((error) {
      print('Error : couldn\'t set speed' + error.toString());
    });
  }
  //------------------------------------------Transport --------------------------------------------
  void setTransport(Transport transport)
  {
    _firestore.collection("users").document(this._id).updateData(
        {
          "Transport": transport.toString(),
        }
    ).then((result) {
      print('speed set');
      _transport = transport;
    }).catchError((error) {
      print('Error : couldn\'t set transport' + error.toString());
    });
  }
  //------------------------------------------Vehicles--------------------------------------------
  Future<void> addVehicule(Vehicule v) {
      _firestore.collection('users').document(_id).collection('vehicules')
          .document(v.matricule).setData({
        'Matricule': v.matricule,
        'Model': v.model,
        'Color': v.color,
      })
          .then((_) {
        this._listVehicles.add(v);
        print('vehicule added');
      }).catchError((error) {
        print('Couldn\'t add vehicule' + error.toString());
      });
    }
    Future<void> removeVehicule(Vehicule v) {
      _firestore.collection('users').document(_id).collection('vehicules')
          .document(v.matricule).delete()
          .then((_) {
        this._listVehicles.remove(v);
        print('Vehicule removed');
      }).catchError((error) {
        print('Couldn\'t remove vehicule' + error.toString());
      });
    }

  //------------------------------------------Historique--------------------------------------------
  // TODO Historique
    Future<void> addToHistorique(TimePlace location) {

    }
    void supprimerHistorique() {
    ///////////////////////////////////////////////////////////////////
        _historique.supprimer();
    }

  void supprimerHistoriqueGroupe(String groupe) {
    /////////////////////////////////////////////////
    _historique.supprimerGroupe(groupe);
  }
  //------------------------------------------Groupes--------------------------------------------
  Future<void> joinGroupe(String gid) {

  }
  Future<void> leaveGroupe(String gid) {

  }
  //------------------------------------------Boite de reception--------------------------------------------
//Getter
    String getId() {
      return this._id;
    }

    String getNom() {
      return this._nom;
    }

    String getPrenom() {
      return this._prenom;
    }

    String getPhone() {
      return this._phone;
    }

    String getEmail() {
      return this._email;
    }

    String getPassword() {
      return this._password;
    }
}
class Vehicule
{
  String matricule;
  String model;
  String color;
  Vehicule(String matricule,String model,String color)
  {
    this.matricule = matricule;
    this.model = model;
    this.color = color;
  }
  @override
  bool operator ==(Object other) => other is Vehicule && other.matricule == this.matricule;

  @override
  int get hashCode => matricule.hashCode;
}

enum Transport
{
  Voiture,Moto,Train,Bus,Bicyclette, Apieds , Autres,
}


