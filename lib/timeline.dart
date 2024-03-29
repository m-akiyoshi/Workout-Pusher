import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workout_pusher/chooseExercise.dart';
import 'package:workout_pusher/dayWorkouts.dart';
import 'package:workout_pusher/main.dart';
import 'package:workout_pusher/penguin.dart';
import 'package:workout_pusher/workouts.dart';

class TimelinePage extends StatefulWidget {
  @override
  _TimelinePageState createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  int _currentIndex = 0;
  List<DayWorkout> dayWorkouts = [];

  Future<List<DocumentSnapshot>> _getWorkoutDataFromDB() async {
    CollectionReference ref = Firestore.instance.collection('dayWorkouts');
    QuerySnapshot eventsQuery = await ref.orderBy('date').getDocuments();
    return eventsQuery.documents;
  }

  void initState() {
    _getWorkoutData();
  }

  Future<Widget> _getImage(path) async {
    Image image;
    await FirebaseStorage.instance
        .ref()
        .child(path)
        .getDownloadURL()
        .then((downloadUrl) {
      image = Image.network(
        downloadUrl.toString(),
        fit: BoxFit.scaleDown,
      );
    });

    return image;
  }

  void _navigateToScreens(index) {
    var nextScreen;
    print(index);
    if (index == 0) {
      nextScreen = ChooseExercisePage();
    } else if (index == 1) {
      nextScreen = TimelinePage();
    } else if (index == 2) {
      nextScreen = PenguinPage();
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  Widget buildRow(dayWorkout) {
    print(dayWorkouts);
    return Card(
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(new DateFormat("yyyy-MM-dd").format(dayWorkout.date),
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      FutureBuilder(
          future: _getImage(dayWorkout.imgUrl),
          builder: (context, snapshot) {
            print(snapshot);
            if (snapshot.connectionState == ConnectionState.done)
              return Container(
                child: snapshot.data,
              );

            if (snapshot.connectionState == ConnectionState.waiting)
              return Container(child: CircularProgressIndicator());

            return Container();
          }),
      Container(
        height: 150,
        child: _myListView(context, dayWorkout.workouts),
      )
    ]));
  }

  _getWorkoutData() async {
    final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
      functionName: 'getDayWorkoutData',
    );

    //パラメーターを渡す
    dynamic resp = await callable.call(<String, dynamic>{
      'data': "d",
    });
    print('getworkout data called and response:');
    print(resp.data);
    var dayWorkoutData = jsonDecode(resp.data);
    dayWorkoutData.forEach((dayWorkout) {
      var dayWorkoutObj = new DayWorkout(DateTime.now(), [], "");
      dayWorkoutObj.date = DateTime.parse(dayWorkout['date']);
      dayWorkoutObj.imgUrl = dayWorkout['imgUrl'];
      dayWorkouts.add(dayWorkoutObj);
    });
    return dayWorkouts;
  }

  Widget _myListView(BuildContext context, List<Workouts> workouts) {
    return ListView.builder(
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Row(children: [
              Text(workouts[index].title,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(width: 10),
              Text(
                  workouts[index].rep.toString() +
                      ' sets ' +
                      workouts[index].sets.toString() +
                      ' reps ' +
                      workouts[index].weight.toString() +
                      ' lbs',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w300)),
            ]),
          ),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text('Timeline'),
        ),
        body: FutureBuilder(
            future: _getWorkoutData(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return Container();
                case ConnectionState.waiting:
                  return new Text('Awaiting result...');
                default:
                  if (snapshot.hasError)
                    return new Text('Error: ${snapshot.error}');
                  else
                    return ListView.builder(
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, index) {
                          return buildRow(snapshot.data[index]);
                        });
              }
            }));
  }
}
